local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local container = script.Parent
local FieldBuilder = require(container:WaitForChild("FieldBuilder"))
local BallController = require(container:WaitForChild("BallController"))
local TeamManager = require(container:WaitForChild("TeamManager"))
local MatchManager = require(container:WaitForChild("MatchManager"))

FieldBuilder.build()
BallController.start()
TeamManager.start()
MatchManager.start(BallController, TeamManager)

print("[TouchSoccer] Server booted.")
