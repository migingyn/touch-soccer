local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local FieldBuilder = {}

local FIELD = Config.Field

local function makePart(name, size, cframe, color, parent, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color or Color3.fromRGB(180, 180, 180)
	p.Anchored = anchored ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function makeLine(name, size, cframe, parent)
	local p = makePart(name, size, cframe, FIELD.LineColor, parent, true)
	p.Material = Enum.Material.Neon
	p.CanCollide = false
	return p
end

local function buildPitch()
	local existing = Workspace:FindFirstChild("SoccerField")
	if existing then existing:Destroy() end

	local root = Instance.new("Model")
	root.Name = "SoccerField"
	root.Parent = Workspace

	local fieldFolder = Instance.new("Folder")
	fieldFolder.Name = "Parts"
	fieldFolder.Parent = root

	local L, W = FIELD.Length, FIELD.Width

	local stripes = 10
	local stripeWidth = W / stripes
	for i = 1, stripes do
		local color = (i % 2 == 0) and FIELD.GrassColor or FIELD.StripeColor
		local z = -W / 2 + stripeWidth * (i - 0.5)
		local stripe = makePart(
			"Stripe" .. i,
			Vector3.new(L, 1, stripeWidth),
			CFrame.new(0, 0, z),
			color,
			fieldFolder,
			true
		)
		stripe.Material = Enum.Material.Grass
	end

	local surround = makePart(
		"Surround",
		Vector3.new(L + 80, 1, W + 80),
		CFrame.new(0, -0.1, 0),
		Color3.fromRGB(42, 110, 48),
		fieldFolder,
		true
	)
	surround.Material = Enum.Material.Grass

	local wallThickness = 2
	local wallHeight = FIELD.WallHeight
	local walls = {
		{ name = "WallNorth", size = Vector3.new(L + wallThickness * 2, wallHeight, wallThickness), cf = CFrame.new(0, wallHeight / 2, -W / 2 - wallThickness / 2) },
		{ name = "WallSouth", size = Vector3.new(L + wallThickness * 2, wallHeight, wallThickness), cf = CFrame.new(0, wallHeight / 2, W / 2 + wallThickness / 2) },
		{ name = "WallWest",  size = Vector3.new(wallThickness, wallHeight, W), cf = CFrame.new(-L / 2 - wallThickness / 2, wallHeight / 2, 0) },
		{ name = "WallEast",  size = Vector3.new(wallThickness, wallHeight, W), cf = CFrame.new(L / 2 + wallThickness / 2, wallHeight / 2, 0) },
	}
	for _, w in ipairs(walls) do
		local part = makePart(w.name, w.size, w.cf, Color3.fromRGB(230, 240, 255), fieldFolder, true)
		part.Material = Enum.Material.Glass
		part.Transparency = 0.75
	end

	local lineHeight = 1.02
	makeLine("HalfLine", Vector3.new(0.5, 0.1, W), CFrame.new(0, lineHeight, 0), fieldFolder)
	local ringRadius = 12
	local ringSegments = 48
	for i = 1, ringSegments do
		local a = (i / ringSegments) * math.pi * 2
		local x = math.cos(a) * ringRadius
		local z = math.sin(a) * ringRadius
		makeLine(
			"CenterCircle_" .. i,
			Vector3.new(0.4, 0.1, (2 * math.pi * ringRadius) / ringSegments + 0.4),
			CFrame.new(x, lineHeight, z) * CFrame.Angles(0, -a + math.pi / 2, 0),
			fieldFolder
		)
	end
	makeLine("CenterSpot", Vector3.new(1.5, 0.1, 1.5), CFrame.new(0, lineHeight, 0), fieldFolder)
	makeLine("SidelineN", Vector3.new(L, 0.1, 0.5), CFrame.new(0, lineHeight, -W / 2 + 1), fieldFolder)
	makeLine("SidelineS", Vector3.new(L, 0.1, 0.5), CFrame.new(0, lineHeight, W / 2 - 1), fieldFolder)
	makeLine("GoallineW", Vector3.new(0.5, 0.1, W), CFrame.new(-L / 2 + 1, lineHeight, 0), fieldFolder)
	makeLine("GoallineE", Vector3.new(0.5, 0.1, W), CFrame.new(L / 2 - 1, lineHeight, 0), fieldFolder)

	local penBoxW, penBoxD = 40, 20
	for _, side in ipairs({ -1, 1 }) do
		local centerX = side * (L / 2 - penBoxD / 2)
		local edgeX = side * (L / 2 - penBoxD)
		makeLine("PenBoxFront" .. side, Vector3.new(0.5, 0.1, penBoxW), CFrame.new(edgeX, lineHeight, 0), fieldFolder)
		makeLine("PenBoxN" .. side, Vector3.new(penBoxD, 0.1, 0.5), CFrame.new(centerX, lineHeight, -penBoxW / 2), fieldFolder)
		makeLine("PenBoxS" .. side, Vector3.new(penBoxD, 0.1, 0.5), CFrame.new(centerX, lineHeight, penBoxW / 2), fieldFolder)
		local smW, smD = 20, 9
		local smEdgeX = side * (L / 2 - smD)
		local smCenterX = side * (L / 2 - smD / 2)
		makeLine("SmallBoxFront" .. side, Vector3.new(0.5, 0.1, smW), CFrame.new(smEdgeX, lineHeight, 0), fieldFolder)
		makeLine("SmallBoxN" .. side, Vector3.new(smD, 0.1, 0.5), CFrame.new(smCenterX, lineHeight, -smW / 2), fieldFolder)
		makeLine("SmallBoxS" .. side, Vector3.new(smD, 0.1, 0.5), CFrame.new(smCenterX, lineHeight, smW / 2), fieldFolder)
		makeLine("PenSpot" .. side, Vector3.new(1.2, 0.1, 1.2), CFrame.new(side * (L / 2 - 15), lineHeight, 0), fieldFolder)
	end
	return root, fieldFolder
end

local function buildGoal(side, color, parent)
	local goalFolder = Instance.new("Folder")
	goalFolder.Name = "Goal_" .. (side < 0 and "Red" or "Blue")
	goalFolder.Parent = parent

	local L = FIELD.Length
	local gw, gh, gd = FIELD.GoalWidth, FIELD.GoalHeight, FIELD.GoalDepth
	local postThickness = 1
	local goalX = side * (L / 2 + gd / 2)

	local back = makePart("Back", Vector3.new(postThickness, gh, gw), CFrame.new(side * (L / 2 + gd), gh / 2, 0), color, goalFolder, true)
	back.Transparency = 0.35
	back.Material = Enum.Material.ForceField
	makePart("TopBarN", Vector3.new(gd + postThickness, postThickness, postThickness), CFrame.new(goalX, gh, -gw / 2), color, goalFolder, true)
	makePart("TopBarS", Vector3.new(gd + postThickness, postThickness, postThickness), CFrame.new(goalX, gh, gw / 2), color, goalFolder, true)
	makePart("Crossbar", Vector3.new(postThickness, postThickness, gw + postThickness), CFrame.new(side * (L / 2), gh, 0), color, goalFolder, true)
	makePart("PostN", Vector3.new(postThickness, gh, postThickness), CFrame.new(side * (L / 2), gh / 2, -gw / 2), color, goalFolder, true)
	makePart("PostS", Vector3.new(postThickness, gh, postThickness), CFrame.new(side * (L / 2), gh / 2, gw / 2), color, goalFolder, true)
	makePart("BackPostN", Vector3.new(postThickness, gh, postThickness), CFrame.new(side * (L / 2 + gd), gh / 2, -gw / 2), color, goalFolder, true)
	makePart("BackPostS", Vector3.new(postThickness, gh, postThickness), CFrame.new(side * (L / 2 + gd), gh / 2, gw / 2), color, goalFolder, true)
	local netN = makePart("NetN", Vector3.new(gd, gh, postThickness), CFrame.new(goalX, gh / 2, -gw / 2), color, goalFolder, true)
	netN.Transparency = 0.6; netN.Material = Enum.Material.ForceField
	local netS = makePart("NetS", Vector3.new(gd, gh, postThickness), CFrame.new(goalX, gh / 2, gw / 2), color, goalFolder, true)
	netS.Transparency = 0.6; netS.Material = Enum.Material.ForceField
	local netTop = makePart("NetTop", Vector3.new(gd, postThickness, gw), CFrame.new(goalX, gh, 0), color, goalFolder, true)
	netTop.Transparency = 0.6; netTop.Material = Enum.Material.ForceField

	local sensor = Instance.new("Part")
	sensor.Name = "GoalSensor"
	sensor.Size = Vector3.new(gd * 0.8, gh - 1, gw - 2)
	sensor.CFrame = CFrame.new(side * (L / 2 + gd / 2), gh / 2, 0)
	sensor.Anchored = true
	sensor.CanCollide = false
	sensor.Transparency = 1
	sensor.Parent = goalFolder

	return goalFolder, sensor
end

local function buildSpawnpoints(parent)
	local folder = Instance.new("Folder")
	folder.Name = "SpawnPoints"
	folder.Parent = parent

	local spawns = { Red = {}, Blue = {} }

	for _, teamKey in ipairs({ "Red", "Blue" }) do
		local team = Config.Teams[teamKey]
		for i = -2, 2 do
			local sp = Instance.new("SpawnLocation")
			sp.Name = teamKey .. "Spawn" .. (i + 3)
			sp.Size = Vector3.new(6, 1, 6)
			sp.Anchored = true
			sp.Neutral = false
			sp.AllowTeamChangeOnTouch = false
			sp.CanCollide = false
			sp.Transparency = 1
			sp.BrickColor = team.Color
			sp.TeamColor = team.Color
			sp.Duration = 0
			sp.CFrame = CFrame.new(team.SpawnOffset + Vector3.new(0, 0, i * 10))
			sp.Parent = folder
			table.insert(spawns[teamKey], sp)
		end
	end

	return folder, spawns
end

function FieldBuilder.build()
	local field = buildPitch()
	local redGoal, redSensor = buildGoal(-1, Config.Field.RedGoalColor, field)
	local blueGoal, blueSensor = buildGoal(1, Config.Field.BlueGoalColor, field)
	local _, spawns = buildSpawnpoints(field)

	local refs = Instance.new("Folder")
	refs.Name = "FieldRefs"
	refs.Parent = ReplicatedStorage
	local function objValue(name, value)
		local v = Instance.new("ObjectValue")
		v.Name = name
		v.Value = value
		v.Parent = refs
	end
	objValue("Field", field)
	objValue("RedGoal", redGoal)
	objValue("BlueGoal", blueGoal)
	objValue("RedGoalSensor", redSensor)
	objValue("BlueGoalSensor", blueSensor)

	return {
		field = field,
		redGoal = redGoal,
		blueGoal = blueGoal,
		redSensor = redSensor,
		blueSensor = blueSensor,
		spawns = spawns,
	}
end

return FieldBuilder
