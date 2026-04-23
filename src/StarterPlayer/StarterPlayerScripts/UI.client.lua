local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TouchSoccerUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, text, size, pos, anchor)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size or UDim2.new(1, 0, 1, 0)
	l.Position = pos or UDim2.new(0, 0, 0, 0)
	l.AnchorPoint = anchor or Vector2.new(0, 0)
	l.Text = text or ""
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.Parent = parent
	return l
end

-- =========================
-- Top scoreboard
-- =========================
local topFrame = Instance.new("Frame")
topFrame.Name = "Scoreboard"
topFrame.AnchorPoint = Vector2.new(0.5, 0)
topFrame.Position = UDim2.new(0.5, 0, 0, 14)
topFrame.Size = UDim2.new(0, 420, 0, 68)
topFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
topFrame.BackgroundTransparency = 0.15
topFrame.BorderSizePixel = 0
topFrame.Parent = gui
Instance.new("UICorner", topFrame).CornerRadius = UDim.new(0, 12)

local redBox = Instance.new("Frame")
redBox.Size = UDim2.new(0, 120, 1, -14)
redBox.Position = UDim2.new(0, 7, 0, 7)
redBox.BackgroundColor3 = Config.Teams.Red.Color3
redBox.BorderSizePixel = 0
redBox.Parent = topFrame
Instance.new("UICorner", redBox).CornerRadius = UDim.new(0, 8)
local redScore = makeLabel(redBox, "0", UDim2.new(1, 0, 1, 0))
redScore.Name = "RedScore"

local blueBox = Instance.new("Frame")
blueBox.Size = UDim2.new(0, 120, 1, -14)
blueBox.Position = UDim2.new(1, -127, 0, 7)
blueBox.BackgroundColor3 = Config.Teams.Blue.Color3
blueBox.BorderSizePixel = 0
blueBox.Parent = topFrame
Instance.new("UICorner", blueBox).CornerRadius = UDim.new(0, 8)
local blueScore = makeLabel(blueBox, "0", UDim2.new(1, 0, 1, 0))
blueScore.Name = "BlueScore"

local centerBox = Instance.new("Frame")
centerBox.BackgroundTransparency = 1
centerBox.Size = UDim2.new(0, 160, 1, 0)
centerBox.Position = UDim2.new(0.5, -80, 0, 0)
centerBox.Parent = topFrame
local timerLabel = makeLabel(centerBox, "3:00", UDim2.new(1, 0, 0.6, 0), UDim2.new(0, 0, 0, 4))
timerLabel.Name = "Timer"
local phaseLabel = makeLabel(centerBox, "Warmup", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.6, 0))
phaseLabel.Name = "Phase"
phaseLabel.TextColor3 = Color3.fromRGB(200, 200, 220)

-- =========================
-- Power meter
-- =========================
local power = Instance.new("Frame")
power.Name = "PowerMeter"
power.AnchorPoint = Vector2.new(0.5, 1)
power.Position = UDim2.new(0.5, 0, 1, -40)
power.Size = UDim2.new(0, 320, 0, 22)
power.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
power.BackgroundTransparency = 0.25
power.BorderSizePixel = 0
power.Visible = false
power.Parent = gui
Instance.new("UICorner", power).CornerRadius = UDim.new(1, 0)

local powerFill = Instance.new("Frame")
powerFill.Size = UDim2.new(0, 0, 1, 0)
powerFill.BackgroundColor3 = Color3.fromRGB(120, 220, 120)
powerFill.BorderSizePixel = 0
powerFill.Parent = power
Instance.new("UICorner", powerFill).CornerRadius = UDim.new(1, 0)

local powerLabel = makeLabel(power, "POWER", UDim2.new(1, 0, 1, 0))
powerLabel.ZIndex = 2
powerLabel.TextColor3 = Color3.new(1, 1, 1)

-- =========================
-- Control hints
-- =========================
local hints = Instance.new("Frame")
hints.AnchorPoint = Vector2.new(0, 1)
hints.Position = UDim2.new(0, 16, 1, -16)
hints.Size = UDim2.new(0, 240, 0, 110)
hints.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
hints.BackgroundTransparency = 0.35
hints.BorderSizePixel = 0
hints.Parent = gui
Instance.new("UICorner", hints).CornerRadius = UDim.new(0, 10)
local function addHint(key, desc, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -16, 0, 22)
	row.Position = UDim2.new(0, 8, 0, 6 + order * 24)
	row.BackgroundTransparency = 1
	row.Parent = hints
	local k = makeLabel(row, key, UDim2.new(0, 100, 1, 0))
	k.TextXAlignment = Enum.TextXAlignment.Left
	k.TextColor3 = Color3.fromRGB(255, 220, 80)
	local d = makeLabel(row, desc, UDim2.new(1, -100, 1, 0), UDim2.new(0, 100, 0, 0))
	d.TextXAlignment = Enum.TextXAlignment.Left
end
addHint("Hold LMB", "Charge shot", 0)
addHint("E", "Pass", 1)
addHint("Q / Shift", "Slide tackle", 2)
addHint("Tab", "Toggle cursor", 3)

-- =========================
-- Team panel (switch teams)
-- =========================
local teamPanel = Instance.new("Frame")
teamPanel.AnchorPoint = Vector2.new(1, 1)
teamPanel.Position = UDim2.new(1, -16, 1, -16)
teamPanel.Size = UDim2.new(0, 200, 0, 84)
teamPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
teamPanel.BackgroundTransparency = 0.35
teamPanel.BorderSizePixel = 0
teamPanel.Parent = gui
Instance.new("UICorner", teamPanel).CornerRadius = UDim.new(0, 10)
local tpLabel = makeLabel(teamPanel, "SWITCH TEAM", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 4))
tpLabel.TextColor3 = Color3.fromRGB(220, 220, 230)

local function makeBtn(text, color, pos)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 84, 0, 44)
	btn.Position = pos
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 18
	btn.BorderSizePixel = 0
	btn.Parent = teamPanel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end
local redBtn = makeBtn("RED", Config.Teams.Red.Color3, UDim2.new(0, 8, 0, 32))
local blueBtn = makeBtn("BLUE", Config.Teams.Blue.Color3, UDim2.new(1, -92, 0, 32))
redBtn.MouseButton1Click:Connect(function() Remotes.JoinTeam:FireServer("Red") end)
blueBtn.MouseButton1Click:Connect(function() Remotes.JoinTeam:FireServer("Blue") end)

-- =========================
-- Notifications
-- =========================
local notice = Instance.new("Frame")
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.Position = UDim2.new(0.5, 0, 0, 100)
notice.Size = UDim2.new(0, 500, 0, 80)
notice.BackgroundTransparency = 1
notice.Parent = gui
local noticeLabel = makeLabel(notice, "", UDim2.new(1, 0, 1, 0))
noticeLabel.TextScaled = true
noticeLabel.TextStrokeTransparency = 0
noticeLabel.Font = Enum.Font.GothamBlack

-- =========================
-- Ball owner indicator (above holder's head)
-- =========================
local ownerMarkers = {}
local function clearOwnerMarkers()
	for _, m in pairs(ownerMarkers) do
		if m.Parent then m:Destroy() end
	end
	ownerMarkers = {}
end

Remotes.BallOwner.OnClientEvent:Connect(function(owner)
	clearOwnerMarkers()
	if owner and owner.Character then
		local head = owner.Character:FindFirstChild("Head")
		if head then
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 44, 0, 44)
			bb.StudsOffset = Vector3.new(0, 4.2, 0)
			bb.AlwaysOnTop = true
			bb.Adornee = head
			bb.Parent = gui
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.new(1, 0, 1, 0)
			icon.BackgroundTransparency = 1
			icon.Text = "⚽"
			icon.TextScaled = true
			icon.Font = Enum.Font.GothamBold
			icon.TextColor3 = Color3.new(1, 1, 1)
			icon.TextStrokeTransparency = 0
			icon.Parent = bb
			table.insert(ownerMarkers, bb)
		end
	end
end)

-- =========================
-- Notification handler
-- =========================
local currentNoticeToken = 0
Remotes.Notification.OnClientEvent:Connect(function(data)
	currentNoticeToken += 1
	local myToken = currentNoticeToken
	noticeLabel.Text = data.text or ""
	noticeLabel.TextColor3 = data.color or Color3.new(1, 1, 1)
	task.delay(data.duration or 2, function()
		if currentNoticeToken == myToken then
			noticeLabel.Text = ""
		end
	end)
end)

-- =========================
-- Match state updates
-- =========================
local function formatTime(t)
	t = math.max(0, math.floor(t))
	local m = math.floor(t / 60)
	local s = t % 60
	return string.format("%d:%02d", m, s)
end

Remotes.MatchState.OnClientEvent:Connect(function(state)
	redScore.Text = tostring(state.score.Red or 0)
	blueScore.Text = tostring(state.score.Blue or 0)
	if state.phase == "Kickoff" and state.countdown and state.countdown > 0 then
		timerLabel.Text = tostring(state.countdown)
		phaseLabel.Text = "Kickoff"
	elseif state.phase == "Live" then
		timerLabel.Text = formatTime(state.timeLeft)
		phaseLabel.Text = "Half " .. (state.half or 1)
	elseif state.phase == "Halftime" then
		timerLabel.Text = "HT"
		phaseLabel.Text = "Halftime"
	elseif state.phase == "FullTime" then
		timerLabel.Text = "FT"
		phaseLabel.Text = "Full Time"
	elseif state.phase == "GoalCelebration" then
		phaseLabel.Text = "GOAL!"
	else
		timerLabel.Text = formatTime(state.timeLeft or 0)
		phaseLabel.Text = state.phase or ""
	end
end)

-- =========================
-- Power meter live update from client input
-- =========================
local chargeValue = ReplicatedStorage:FindFirstChild("ChargePercent")
if not chargeValue then
	chargeValue = Instance.new("NumberValue")
	chargeValue.Name = "ChargePercent"
	chargeValue.Value = 0
	chargeValue.Parent = ReplicatedStorage
end

RunService.RenderStepped:Connect(function()
	local v = chargeValue.Value
	if v > 0.01 then
		power.Visible = true
		powerFill.Size = UDim2.new(v, 0, 1, 0)
		-- Color gradient green -> yellow -> red
		local color
		if v < 0.5 then
			color = Color3.fromRGB(120 + (255 - 120) * (v / 0.5), 220, 120 - 80 * (v / 0.5))
		else
			local t = (v - 0.5) / 0.5
			color = Color3.fromRGB(255, 220 - 160 * t, 40)
		end
		powerFill.BackgroundColor3 = color
	else
		power.Visible = false
	end
end)

-- =========================
-- Mobile buttons
-- =========================
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
	local mobileFrame = Instance.new("Frame")
	mobileFrame.AnchorPoint = Vector2.new(1, 1)
	mobileFrame.Position = UDim2.new(1, -16, 1, -120)
	mobileFrame.Size = UDim2.new(0, 210, 0, 70)
	mobileFrame.BackgroundTransparency = 1
	mobileFrame.Parent = gui

	local function mobileBtn(text, color, xOffset, onClick)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 96, 0, 64)
		b.Position = UDim2.new(0, xOffset, 0, 0)
		b.BackgroundColor3 = color
		b.Text = text
		b.Font = Enum.Font.GothamBlack
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextSize = 18
		b.BorderSizePixel = 0
		b.Parent = mobileFrame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	mobileBtn("PASS", Color3.fromRGB(80, 170, 80), 0, function()
		if _G.TouchSoccerInput then _G.TouchSoccerInput.pass() end
	end)
	mobileBtn("TACKLE", Color3.fromRGB(200, 120, 60), 110, function()
		if _G.TouchSoccerInput then _G.TouchSoccerInput.tackle() end
	end)
end
