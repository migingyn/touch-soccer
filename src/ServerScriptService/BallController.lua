local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local BallController = {}

local BALL_NAME = "SoccerBall"

local state = {
	ball = nil,
	owner = nil,
	lastTouch = nil,
	lastTouchTeam = nil,
	ownerCooldownUntil = 0,
	chargeStart = {},
	lastKickAt = {},
	lastPassAt = {},
	lastTackleAt = {},
	stunnedUntil = {},
	frozen = false,
	inputLocked = false,
}

BallController.state = state

local function getCharacterRoot(player)
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function createBall()
	local existing = Workspace:FindFirstChild(BALL_NAME)
	if existing then existing:Destroy() end

	local ball = Instance.new("Part")
	ball.Name = BALL_NAME
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(Config.Ball.Radius * 2, Config.Ball.Radius * 2, Config.Ball.Radius * 2)
	ball.Color = Config.Ball.Color
	ball.Material = Enum.Material.SmoothPlastic
	ball.TopSurface = Enum.SurfaceType.Smooth
	ball.BottomSurface = Enum.SurfaceType.Smooth
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.35, Config.Ball.Bounciness, 0.5, 1)
	ball.Massless = false
	ball.CanCollide = true
	ball.Anchored = false
	ball.Position = Config.Ball.HomePosition
	ball.Parent = Workspace

	local attachment = Instance.new("Attachment")
	attachment.Name = "BallAttachment"
	attachment.Parent = ball

	local dribbleForce = Instance.new("VectorForce")
	dribbleForce.Name = "DribbleForce"
	dribbleForce.Attachment0 = attachment
	dribbleForce.ApplyAtCenterOfMass = true
	dribbleForce.RelativeTo = Enum.ActuatorRelativeTo.World
	dribbleForce.Force = Vector3.zero
	dribbleForce.Parent = ball

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailA"
	att1.Position = Vector3.new(0, 0.5, 0)
	att1.Parent = ball
	local att2 = Instance.new("Attachment")
	att2.Name = "TrailB"
	att2.Position = Vector3.new(0, -0.5, 0)
	att2.Parent = ball
	local trail = Instance.new("Trail")
	trail.Attachment0 = att1
	trail.Attachment1 = att2
	trail.Lifetime = 0.25
	trail.MinLength = 0.2
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = ball

	return ball
end

local function setOwner(player)
	if state.owner == player then return end
	state.owner = player
	if player then
		state.lastTouch = player
		state.lastTouchTeam = player.Team and player.Team.Name or nil
	end
	Remotes.BallOwner:FireAllClients(player)
end

function BallController.resetBall(position, freezeSeconds)
	if not state.ball then return end
	setOwner(nil)
	state.lastKickAt = {}
	state.chargeStart = {}
	state.ball.AssemblyLinearVelocity = Vector3.zero
	state.ball.AssemblyAngularVelocity = Vector3.zero
	state.ball.CFrame = CFrame.new(position or Config.Ball.HomePosition)

	if freezeSeconds and freezeSeconds > 0 then
		state.frozen = true
		state.ball.Anchored = true
		task.delay(freezeSeconds, function()
			if state.ball and state.ball.Parent then
				state.ball.Anchored = false
			end
			state.frozen = false
		end)
	end
end

function BallController.lockInput(locked)
	state.inputLocked = locked and true or false
end

function BallController.getBall()
	return state.ball
end

function BallController.getOwner()
	return state.owner
end

function BallController.getLastTouch()
	return state.lastTouch, state.lastTouchTeam
end

local function pickCandidateOwner()
	if not state.ball then return nil end
	local bestPlayer, bestDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local now = tick()
		if state.stunnedUntil[player] and now < state.stunnedUntil[player] then
			continue
		end
		if state.ownerCooldownUntil > now and state.lastTouch == player then
			continue
		end
		local root = getCharacterRoot(player)
		if not root then continue end
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then continue end
		local d = (root.Position - state.ball.Position).Magnitude
		if d < Config.Ball.MagnetDistance and d < bestDist then
			bestDist = d
			bestPlayer = player
		end
	end
	return bestPlayer, bestDist
end

local function applyDribble()
	local ball = state.ball
	if not ball or state.frozen then return end

	local candidate = pickCandidateOwner()
	local dribbleForce = ball:FindFirstChild("DribbleForce")
	if not dribbleForce then return end

	if candidate then
		setOwner(candidate)
		local root = getCharacterRoot(candidate)
		if root then
			local look = root.CFrame.LookVector
			local target = root.Position + look * Config.Ball.MagnetHoldDistance - Vector3.new(0, 1.5, 0)
			local toTarget = target - ball.Position
			local desired = toTarget * Config.Ball.MagnetStrength
			local rootVel = root.AssemblyLinearVelocity
			local relVel = ball.AssemblyLinearVelocity - rootVel
			desired = desired - relVel * 8
			dribbleForce.Force = Vector3.new(desired.X, desired.Y * 0.25, desired.Z) * Config.Ball.Mass
		end
	else
		if state.owner then
			setOwner(nil)
		end
		dribbleForce.Force = Vector3.zero
	end

	local v = ball.AssemblyLinearVelocity
	if v.Magnitude > Config.Ball.MaxSpeed then
		ball.AssemblyLinearVelocity = v.Unit * Config.Ball.MaxSpeed
	end
end

local function fireBall(player, power, direction, lift)
	local ball = state.ball
	if not ball then return end
	local dir = direction
	if not dir or dir.Magnitude < 0.1 then
		local root = getCharacterRoot(player)
		if not root then return end
		dir = root.CFrame.LookVector
	else
		dir = dir.Unit
	end
	local liftAmt = lift or Config.Kick.UpwardBias
	local launch = (dir + Vector3.new(0, liftAmt, 0)).Unit * power
	ball.AssemblyLinearVelocity = launch
	ball.AssemblyAngularVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
	state.ownerCooldownUntil = tick() + 0.35
	state.lastTouch = player
	state.lastTouchTeam = player.Team and player.Team.Name or nil
	setOwner(nil)
end

local function playerHasBall(player)
	if state.owner == player then return true end
	local root = getCharacterRoot(player)
	if not root or not state.ball then return false end
	return (root.Position - state.ball.Position).Magnitude <= Config.Kick.KickRange
end

function BallController.start()
	state.ball = createBall()

	Remotes.ChargeKick.OnServerEvent:Connect(function(player)
		if state.inputLocked then return end
		state.chargeStart[player] = tick()
	end)

	Remotes.ReleaseKick.OnServerEvent:Connect(function(player, direction)
		if state.inputLocked then return end
		if typeof(direction) ~= "Vector3" then direction = Vector3.zero end
		local now = tick()
		if (state.lastKickAt[player] or 0) + Config.Kick.Cooldown > now then return end
		if not playerHasBall(player) then
			state.chargeStart[player] = nil
			return
		end
		local startT = state.chargeStart[player] or now
		local chargeDur = math.clamp(now - startT, 0, Config.Kick.ChargeTime)
		local t = chargeDur / Config.Kick.ChargeTime
		local power = Config.Kick.MinPower + (Config.Kick.MaxPower - Config.Kick.MinPower) * t
		fireBall(player, power, direction, Config.Kick.UpwardBias * (0.6 + 0.6 * t))
		state.lastKickAt[player] = now
		state.chargeStart[player] = nil
	end)

	Remotes.Pass.OnServerEvent:Connect(function(player, direction)
		if state.inputLocked then return end
		if typeof(direction) ~= "Vector3" then direction = Vector3.zero end
		local now = tick()
		if (state.lastPassAt[player] or 0) + Config.Kick.PassCooldown > now then return end
		if not playerHasBall(player) then return end

		local root = getCharacterRoot(player)
		if root then
			local best, bestScore = nil, -math.huge
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player and other.Team == player.Team then
					local oroot = getCharacterRoot(other)
					if oroot then
						local to = oroot.Position - root.Position
						local dist = to.Magnitude
						if dist > 4 and dist < 80 then
							local dirToTeammate = to.Unit
							local aim = direction.Magnitude > 0.1 and direction.Unit or root.CFrame.LookVector
							local dot = dirToTeammate:Dot(aim)
							if dot > 0.55 then
								local score = dot * 2 - dist * 0.01
								if score > bestScore then
									bestScore, best = score, oroot
								end
							end
						end
					end
				end
			end
			if best then
				direction = (best.Position - root.Position)
			end
		end

		fireBall(player, Config.Kick.PassPower, direction, 0.12)
		state.lastPassAt[player] = now
	end)

	Remotes.Tackle.OnServerEvent:Connect(function(player)
		if state.inputLocked then return end
		local now = tick()
		if (state.lastTackleAt[player] or 0) + Config.Tackle.Cooldown > now then return end
		state.lastTackleAt[player] = now

		local char = player.Character
		local root = getCharacterRoot(player)
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end

		local slideDir = root.CFrame.LookVector
		local flat = Vector3.new(slideDir.X, 0, slideDir.Z)
		if flat.Magnitude < 0.01 then return end
		root.AssemblyLinearVelocity = flat.Unit * Config.Tackle.Speed + Vector3.new(0, 4, 0)
		humanoid.PlatformStand = true

		task.delay(Config.Tackle.Duration, function()
			if humanoid and humanoid.Parent then
				humanoid.PlatformStand = false
			end
		end)

		task.delay(0.1, function()
			if not state.ball then return end
			local current = root and root.Parent and root.Position or nil
			if not current then return end
			local ballPos = state.ball.Position
			if (current - ballPos).Magnitude <= Config.Tackle.StealRange then
				state.lastTouch = player
				state.lastTouchTeam = player.Team and player.Team.Name or nil
				setOwner(player)
				for _, other in ipairs(Players:GetPlayers()) do
					if other ~= player then
						local oroot = getCharacterRoot(other)
						if oroot and (oroot.Position - current).Magnitude < Config.Tackle.StealRange + 2 then
							local ohum = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
							if ohum then
								ohum.PlatformStand = true
								state.stunnedUntil[other] = tick() + Config.Tackle.StunTime
								task.delay(Config.Tackle.StunTime, function()
									if ohum and ohum.Parent then
										ohum.PlatformStand = false
									end
								end)
							end
						end
					end
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		state.chargeStart[player] = nil
		state.lastKickAt[player] = nil
		state.lastPassAt[player] = nil
		state.lastTackleAt[player] = nil
		state.stunnedUntil[player] = nil
		if state.owner == player then
			setOwner(nil)
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not state.ball or not state.ball.Parent then
			state.ball = createBall()
		end
		applyDribble()
	end)
end

return BallController
