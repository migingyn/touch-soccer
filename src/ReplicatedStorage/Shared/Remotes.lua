local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function getOrCreateRemote(parent, name, className)
	local remote = parent:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = parent
	end
	return remote
end

local Remotes = {}

local folder = getOrCreateFolder(ReplicatedStorage, "TouchSoccerRemotes")

Remotes.ChargeKick = getOrCreateRemote(folder, "ChargeKick", "RemoteEvent")
Remotes.ReleaseKick = getOrCreateRemote(folder, "ReleaseKick", "RemoteEvent")
Remotes.Pass = getOrCreateRemote(folder, "Pass", "RemoteEvent")
Remotes.Tackle = getOrCreateRemote(folder, "Tackle", "RemoteEvent")
Remotes.JoinTeam = getOrCreateRemote(folder, "JoinTeam", "RemoteEvent")
Remotes.MatchState = getOrCreateRemote(folder, "MatchState", "RemoteEvent")
Remotes.Notification = getOrCreateRemote(folder, "Notification", "RemoteEvent")
Remotes.BallOwner = getOrCreateRemote(folder, "BallOwner", "RemoteEvent")

Remotes.Folder = folder

return Remotes
