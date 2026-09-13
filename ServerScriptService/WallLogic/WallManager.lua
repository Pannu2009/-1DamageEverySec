local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Shared.WallConfig)
local WallEvent = ReplicatedStorage.Remotes.WallEvent

local WallManager = {}
local PlayerProgress = {}

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
end)

return WallManager
