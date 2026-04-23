local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local charging = false
local chargeStartAt = 0

local uiChargeBindable = ReplicatedStorage:FindFirstChild("ChargePercent")
if not uiChargeBindable then
	uiChargeBindable = Instance.new("NumberValue")
	uiChargeBindable.Name = "ChargePercent"
	uiChargeBindable.Value = 0
	uiChargeBindable.Parent = ReplicatedStorage
end

local function aimDirection()
	local look = camera.CFrame.LookVector
	-- Keep the kick direction grounded so short kicks go forward, not into the sky
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.001 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

local function startCharge()
	if charging then return end
	charging = true
	chargeStartAt = tick()
	Remotes.ChargeKick:FireServer()
end

local function releaseCharge()
	if not charging then return end
	charging = false
	uiChargeBindable.Value = 0
	Remotes.ReleaseKick:FireServer(aimDirection())
end

local function pass()
	Remotes.Pass:FireServer(aimDirection())
end

local function tackle()
	Remotes.Tackle:FireServer()
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startCharge()
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonB then
		pass()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonX then
		tackle()
	elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
		startCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		releaseCharge()
	end
end)

-- Update charge display for UI
RunService.RenderStepped:Connect(function()
	if charging then
		local t = math.clamp((tick() - chargeStartAt) / Config.Kick.ChargeTime, 0, 1)
		uiChargeBindable.Value = t
	end
end)

-- Touch controls (mobile): tap-and-hold to charge shoots; two-finger tap passes; swipe-tackle from a side button (added by UI)
do
	local touchHolding = false
	UserInputService.TouchStarted:Connect(function(input, gpe)
		if gpe then return end
		touchHolding = true
		startCharge()
	end)
	UserInputService.TouchEnded:Connect(function()
		if touchHolding then
			touchHolding = false
			releaseCharge()
		end
	end)
end

-- Expose helpers for the on-screen mobile buttons
_G.TouchSoccerInput = {
	pass = pass,
	tackle = tackle,
	startCharge = startCharge,
	releaseCharge = releaseCharge,
}
