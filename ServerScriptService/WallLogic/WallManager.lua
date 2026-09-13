local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Shared.WallConfig)
local WallEvent = ReplicatedStorage.Remotes.WallEvent
local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

local WallManager = {}
local PlayerProgress = {}

-- Local function to process a win claim for a player
local function claimWin(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	local group = WallConfig.Groups[data.GroupIndex]
	local winReward = group and group.WinReward or 1

	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Wins") then
		stats.Wins.Value += winReward
	end

	data.TotalWins += winReward
	data.GroupIndex = 1
	data.WallIndex = 1
	data.CurrentHP = WallConfig.GetMaxHP(1, 1)

	if player.Character and workspace:FindFirstChild("SpawnLocation") then
		player.Character:MoveTo(workspace.SpawnLocation.Position)
	end

	WallEvent:FireClient(player, "ResetProgress")
end

-- Initialize player session data
Players.PlayerAdded:Connect(function(player)
	PlayerProgress[player.UserId] = {
		GroupIndex = 1,
		WallIndex = 1,
		CurrentHP = WallConfig.GetMaxHP(1, 1),
		TotalWins = 0,
	}
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerProgress[player.UserId] = nil
end)

-- Remote Event handling (for damage or manual remote calls)
WallEvent.OnServerEvent:Connect(function(player, action, payload)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	if action == "DamageWall" then
		local damage = payload or 1
		data.CurrentHP = math.max(0, data.CurrentHP - damage)

		if data.CurrentHP <= 0 then
			data.WallIndex += 1
			data.CurrentHP = WallConfig.GetMaxHP(data.GroupIndex, data.WallIndex) or 0

			WallEvent:FireClient(player, "BreakWall", {
				GroupIndex = data.GroupIndex,
				WallIndex = data.WallIndex - 1
			})
		end

	elseif action == "ClaimWin" then
		claimWin(player)
	end
end)

-- Setup Touched events for WinsGroup parts inside each zone
for _, group in ipairs(wallFolder:GetChildren()) do
	for _, child in ipairs(group:GetChildren()) do
		if child.Name:find("WinsGroup") and child:IsA("BasePart") then
			child.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if player then
					local data = PlayerProgress[player.UserId]
					local groupConfig = WallConfig.Groups[data.GroupIndex]
					
					-- Verify player broke all walls in their current group before allowing win touch
					if data and groupConfig and data.WallIndex > #groupConfig.Healths then
						claimWin(player)
					end
				end
			end)
		end
	end
end

return WallManager
