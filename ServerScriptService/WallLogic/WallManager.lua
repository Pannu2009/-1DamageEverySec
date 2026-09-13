local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Shared.WallConfig)
local WallEvent = ReplicatedStorage.Remotes.WallEvent

local WallManager = {}
local PlayerProgress = {}

-- Initialize player session state
Players.PlayerAdded:Connect(function(player)
	PlayerProgress[player.UserId] = {
		GroupIndex = 1,
		WallIndex = 1,
		CurrentHP = WallConfig.GetMaxHP(1, 1), -- Helper function in WallConfig
		TotalWins = 0,
	}
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerProgress[player.UserId] = nil
end)

-- Process incoming hits from client
WallEvent.OnServerEvent:Connect(function(player, action, payload)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	if action == "DamageWall" then
		local damage = payload or 1
		data.CurrentHP = math.max(0, data.CurrentHP - damage)

		-- If current wall breaks, move to next wall index
		if data.CurrentHP <= 0 then
			data.WallIndex += 1
			data.CurrentHP = WallConfig.GetMaxHP(data.GroupIndex, data.WallIndex) or 0
			
			-- Notify the client to break the wall locally
			WallEvent:FireClient(player, "BreakWall", {
				GroupIndex = data.GroupIndex,
				WallIndex = data.WallIndex - 1
			})
		end
		
	elseif action == "ClaimWin" then
		-- Verify player reached win area server-side before awarding
		data.TotalWins += 1
		data.GroupIndex = 1
		data.WallIndex = 1
		data.CurrentHP = WallConfig.GetMaxHP(1, 1)

		-- Teleport back to spawn locally/server-side & notify client to reset walls
		player.Character:MoveTo(workspace.SpawnLocation.Position)
		WallEvent:FireClient(player, "ResetProgress")
	end
end)

return WallManager
