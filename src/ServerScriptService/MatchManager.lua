local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MatchManager = {}

local match = {
	phase = "Warmup", -- Warmup | Kickoff | Live | Halftime | FullTime
	half = 1,
	timeLeft = Config.Match.HalfDurationSeconds,
	score = { Red = 0, Blue = 0 },
	running = false,
	countdown = 0,
}

MatchManager.match = match

local BallController -- set on start()
local TeamManager

local function broadcast()
	Remotes.MatchState:FireAllClients({
		phase = match.phase,
		half = match.half,
		timeLeft = match.timeLeft,
		score = match.score,
		countdown = match.countdown,
	})
end

local function notify(text, color, duration)
	Remotes.Notification:FireAllClients({
		text = text,
		color = color,
		duration = duration or 2.5,
	})
end

local function freezeAllCharacters(freeze)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum then
			hum.WalkSpeed = freeze and 0 or 16
			hum.JumpPower = freeze and 0 or 50
		end
		if root and freeze then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

local function doKickoff(countdownSeconds)
	match.phase = "Kickoff"
	match.countdown = countdownSeconds
	BallController.resetBall(Config.Ball.HomePosition, countdownSeconds)
	BallController.lockInput(true)
	TeamManager.respawnAllAtFormation()
	freezeAllCharacters(true)
	broadcast()

	for i = countdownSeconds, 1, -1 do
		match.countdown = i
		broadcast()
		notify(tostring(i), Color3.fromRGB(255, 220, 80), 0.9)
		task.wait(1)
	end
	match.countdown = 0
	match.phase = "Live"
	BallController.lockInput(false)
	freezeAllCharacters(false)
	notify("GO!", Color3.fromRGB(120, 255, 120), 1.2)
	broadcast()
end

local function onGoalScored(scoringTeamName)
	if match.phase ~= "Live" then return end
	match.phase = "GoalCelebration"
	match.score[scoringTeamName] = (match.score[scoringTeamName] or 0) + 1
	local lastTouch = BallController.getLastTouch()
	local scorerName = lastTouch and (lastTouch.DisplayName or lastTouch.Name) or "Own goal"
	notify("GOAL! " .. scoringTeamName .. " — " .. scorerName, scoringTeamName == "Red" and Config.Teams.Red.Color3 or Config.Teams.Blue.Color3, Config.Match.GoalCelebrationSeconds)
	BallController.lockInput(true)
	broadcast()
	task.wait(Config.Match.GoalCelebrationSeconds)
	doKickoff(Config.Match.KickoffCountdownSeconds)
end

local function setupGoalSensors()
	local refs = ReplicatedStorage:WaitForChild("FieldRefs")
	local redSensor = refs:WaitForChild("RedGoalSensor").Value
	local blueSensor = refs:WaitForChild("BlueGoalSensor").Value
	assert(redSensor and blueSensor, "Goal sensors missing")

	local function sensorConnect(sensor, goalForTeamName)
		sensor.Touched:Connect(function(hit)
			local ball = BallController.getBall()
			if not ball or hit ~= ball then return end
			if match.phase ~= "Live" then return end
			-- Red goal belongs to Red, so Blue scores when ball enters Red's goal
			local scoringTeam = goalForTeamName == "Red" and "Blue" or "Red"
			onGoalScored(scoringTeam)
		end)
	end

	sensorConnect(redSensor, "Red")
	sensorConnect(blueSensor, "Blue")
end

local function endHalf()
	if match.half == 1 then
		match.phase = "Halftime"
		match.half = 2
		match.timeLeft = Config.Match.HalfDurationSeconds
		notify("Halftime", Color3.fromRGB(255, 220, 80), Config.Match.HalftimeBreakSeconds)
		BallController.lockInput(true)
		broadcast()
		task.wait(Config.Match.HalftimeBreakSeconds)
		doKickoff(Config.Match.KickoffCountdownSeconds)
	else
		match.phase = "FullTime"
		local winner
		if match.score.Red > match.score.Blue then winner = "Red"
		elseif match.score.Blue > match.score.Red then winner = "Blue"
		else winner = "Draw" end
		notify("Full Time — " .. (winner == "Draw" and "Draw!" or (winner .. " wins!")), Color3.fromRGB(255, 255, 255), 6)
		BallController.lockInput(true)
		broadcast()
		task.wait(8)
		-- Reset
		match.score = { Red = 0, Blue = 0 }
		match.half = 1
		match.timeLeft = Config.Match.HalfDurationSeconds
		doKickoff(Config.Match.KickoffCountdownSeconds)
	end
end

function MatchManager.start(ballCtrl, teamMgr)
	BallController = ballCtrl
	TeamManager = teamMgr

	setupGoalSensors()

	task.spawn(function()
		-- Wait for at least the minimum player count
		while #Players:GetPlayers() < Config.Match.MinPlayersToStart do
			match.phase = "Warmup"
			match.timeLeft = Config.Match.HalfDurationSeconds
			broadcast()
			task.wait(1)
		end

		doKickoff(Config.Match.KickoffCountdownSeconds)

		local lastTick = tick()
		while true do
			RunService.Heartbeat:Wait()
			local now = tick()
			local dt = now - lastTick
			lastTick = now

			if match.phase == "Live" then
				match.timeLeft = math.max(0, match.timeLeft - dt)
				broadcast()
				if match.timeLeft <= 0 then
					endHalf()
					lastTick = tick()
				end
			end
		end
	end)
end

return MatchManager
