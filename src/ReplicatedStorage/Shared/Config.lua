local Config = {}

Config.Field = {
	Length = 180,
	Width = 110,
	GoalWidth = 28,
	GoalHeight = 14,
	GoalDepth = 10,
	WallHeight = 30,
	GrassColor = Color3.fromRGB(62, 140, 58),
	StripeColor = Color3.fromRGB(52, 122, 50),
	LineColor = Color3.fromRGB(240, 240, 240),
	RedGoalColor = Color3.fromRGB(200, 60, 60),
	BlueGoalColor = Color3.fromRGB(60, 110, 200),
}

Config.Ball = {
	Radius = 1.2,
	Mass = 2.5,
	Color = Color3.fromRGB(245, 245, 245),
	MagnetDistance = 7,
	MagnetHoldDistance = 3.5,
	MagnetStrength = 140,
	MaxSpeed = 220,
	AirResistance = 0.015,
	GroundFriction = 1.2,
	Bounciness = 0.55,
	HomePosition = Vector3.new(0, 3, 0),
}

Config.Match = {
	HalfDurationSeconds = 180,
	HalftimeBreakSeconds = 10,
	KickoffCountdownSeconds = 3,
	GoalCelebrationSeconds = 4,
	MinPlayersToStart = 1,
}

Config.Kick = {
	MinPower = 45,
	MaxPower = 180,
	ChargeTime = 1.1,
	Cooldown = 0.45,
	UpwardBias = 0.28,
	PassPower = 95,
	PassCooldown = 0.35,
	KickRange = 6.5,
	HeightAssist = 0.35,
}

Config.Tackle = {
	Duration = 0.55,
	Cooldown = 2.5,
	Speed = 48,
	StealRange = 5.5,
	StunTime = 1.6,
}

Config.Teams = {
	Red = {
		Name = "Red",
		Color = BrickColor.new("Bright red"),
		Color3 = Color3.fromRGB(220, 60, 60),
		SpawnOffset = Vector3.new(-40, 4, 0),
	},
	Blue = {
		Name = "Blue",
		Color = BrickColor.new("Bright blue"),
		Color3 = Color3.fromRGB(60, 110, 220),
		SpawnOffset = Vector3.new(40, 4, 0),
	},
}

return Config
