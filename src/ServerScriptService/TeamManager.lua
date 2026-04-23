local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local TeamManager = {}

local function ensureTeam(name, color3, brickColor)
	local team = Teams:FindFirstChild(name)
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.TeamColor = brickColor
		team.AutoAssignable = false
		team.Parent = Teams
	end
	return team
end

function TeamManager.start()
	ensureTeam("Red", Config.Teams.Red.Color3, Config.Teams.Red.Color)
	ensureTeam("Blue", Config.Teams.Blue.Color3, Config.Teams.Blue.Color)

	local function assignToSmallerTeam(player)
		local red, blue = Teams.Red, Teams.Blue
		local redCount, blueCount = #red:GetPlayers(), #blue:GetPlayers()
		player.Team = (redCount <= blueCount) and red or blue
		player.TeamColor = player.Team.TeamColor
		player.Neutral = false
	end

	local function recolorCharacter(player)
		local char = player.Character
		if not char then return end
		local team = player.Team
		if not team then return end
		local color = team.Name == "Red" and Config.Teams.Red.Color3 or Config.Teams.Blue.Color3
		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("Shirt") or desc:IsA("Pants") or desc:IsA("ShirtGraphic") then
				desc:Destroy()
			end
		end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not part:IsA("Accessory") then
				if part.Name == "Head" or part.Name:find("UpperTorso") or part.Name:find("LowerTorso") or part.Name:find("Arm") or part.Name:find("Leg") or part.Name == "Torso" or part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Left Leg" or part.Name == "Right Leg" then
					part.Color = color
				end
			end
		end
		-- Add a glowing team band overhead
		local head = char:FindFirstChild("Head")
		if head then
			local existing = head:FindFirstChild("TeamBillboard")
			if existing then existing:Destroy() end
			local bb = Instance.new("BillboardGui")
			bb.Name = "TeamBillboard"
			bb.Size = UDim2.new(0, 120, 0, 24)
			bb.StudsOffset = Vector3.new(0, 2.6, 0)
			bb.AlwaysOnTop = true
			bb.Parent = head

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = color
			frame.BackgroundTransparency = 0.2
			frame.BorderSizePixel = 0
			frame.Parent = bb
			local corner = Instance.new("UICorner", frame)
			corner.CornerRadius = UDim.new(0, 6)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = player.DisplayName or player.Name
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.3
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.Parent = frame
		end
	end

	local function onCharacterAdded(player, character)
		character:WaitForChild("Humanoid")
		task.wait(0.15)
		recolorCharacter(player)
	end

	local function onPlayerAdded(player)
		assignToSmallerTeam(player)
		player.CharacterAdded:Connect(function(char)
			onCharacterAdded(player, char)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerAdded(p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Remotes.JoinTeam.OnServerEvent:Connect(function(player, teamName)
		if teamName ~= "Red" and teamName ~= "Blue" then return end
		local team = Teams:FindFirstChild(teamName)
		if not team then return end
		player.Team = team
		player.TeamColor = team.TeamColor
		player.Neutral = false
		if player.Character then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Health = 0
			end
		end
	end)
end

function TeamManager.respawnAllAtFormation()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local team = player.Team
			if team then
				local offset = team.Name == "Red" and Config.Teams.Red.SpawnOffset or Config.Teams.Blue.SpawnOffset
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(offset + Vector3.new(0, 0, math.random(-15, 15))) * CFrame.Angles(0, team.Name == "Red" and 0 or math.pi, 0)
					root.AssemblyLinearVelocity = Vector3.zero
					hum.PlatformStand = false
				end
			end
		end
	end
end

return TeamManager
