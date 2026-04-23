local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

camera.CameraType = Enum.CameraType.Scriptable

local yaw, pitch = 0, math.rad(-15)
local sensitivity = 0.004
local distance = 18
local minPitch, maxPitch = math.rad(-75), math.rad(35)
local locked = true

local function setMouseBehavior()
	UserInputService.MouseBehavior = locked and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not locked
end
setMouseBehavior()

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and locked then
		yaw = yaw - input.Delta.X * sensitivity
		pitch = math.clamp(pitch - input.Delta.Y * sensitivity, minPitch, maxPitch)
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		distance = math.clamp(distance - input.Position.Z * 2, 10, 34)
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		locked = not locked
		setMouseBehavior()
	end
end)

local function focusPosition()
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

RunService.RenderStepped:Connect(function()
	local focus = focusPosition()
	if not focus then return end
	local offset = Vector3.new(
		math.sin(yaw) * math.cos(pitch),
		-math.sin(pitch),
		math.cos(yaw) * math.cos(pitch)
	) * distance

	local camPos = focus + Vector3.new(0, 3, 0) + offset
	camera.CFrame = CFrame.new(camPos, focus + Vector3.new(0, 2, 0))
end)

-- When the character dies or resets, keep the camera behavior consistent
player.CharacterAdded:Connect(function()
	camera.CameraType = Enum.CameraType.Scriptable
end)
