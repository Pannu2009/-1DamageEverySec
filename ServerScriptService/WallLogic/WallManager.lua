local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Shared:WaitForChild("WallsConfig"))
local WallEvent = ReplicatedStorage.Remotes.WallEvent
local RebirthEvent = ReplicatedStorage.Remotes.RebirthEvent
local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

local WallManager = {}
local PlayerProgress = {}
local claimDebounce = {}

-- Read damage from the server-side sword attribute (never trust the client)
local function getSwordDamage(player)
	local char = player.Character
	local sword = char and char:FindFirstChild("Sword")
	if not sword and player:FindFirstChild("Backpack") then
		sword = player.Backpack:FindFirstChild("Sword")
	end
	if sword then
		local d = sword:GetAttribute("Damage")
		if typeof(d) == "number" and d > 0 then
			return d
		end
	end
	return 1
end

-- Teleport the player in front of a wall
local function teleportToWall(player, groupIndex, wallIndex)
	local char = player.Character
	if not char then return end
	local spawnLoc = workspace:FindFirstChild("SpawnLocation")
	local folder = wallFolder:FindFirstChild("Group" .. groupIndex)
	local wall = folder and folder:FindFirstChild("Wall" .. wallIndex)
	if wall and spawnLoc then
		char:PivotTo(CFrame.new(
			wall.Position.X,
			spawnLoc.Position.Y + 3,
			wall.Position.Z + 14
		))
	elseif spawnLoc then
		char:PivotTo(CFrame.new(spawnLoc.Position + Vector3.new(0, 3, 0)))
	end
end

-- Tell the client which wall is current so it can show the wall GUI
local function notifyNewWall(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end
	WallEvent:FireClient(player, "NewWall", {
		GroupIndex = data.GroupIndex,
		WallIndex = data.WallIndex,
		HP = data.CurrentHP,
		MaxHP = WallConfig.GetMaxHP(data.GroupIndex, data.WallIndex),
	})
end

-- Claiming wins is OPTIONAL: it banks the unclaimed wins the player has
-- earned so far and resets them back to Group 1. Players can also just
-- keep advancing zones to earn even more unclaimed wins.
local function claimWin(player)
	if claimDebounce[player.UserId] then return end
	claimDebounce[player.UserId] = true
	task.delay(2, function()
		claimDebounce[player.UserId] = nil
	end)

	local data = PlayerProgress[player.UserId]
	if not data or data.PendingWins <= 0 then return end

	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Wins") then
		stats.Wins.Value += data.PendingWins
	end
	data.TotalWins += data.PendingWins
	data.PendingWins = 0

	-- Reset back to the first zone
	data.GroupIndex = 1
	data.WallIndex = 1
	data.CurrentHP = WallConfig.GetMaxHP(1, 1)

	-- Back to spawn
	local spawnLoc = workspace:FindFirstChild("SpawnLocation")
	if player.Character and spawnLoc then
		player.Character:PivotTo(CFrame.new(spawnLoc.Position + Vector3.new(0, 3, 0)))
	end

	WallEvent:FireClient(player, "ResetProgress")
	notifyNewWall(player)
	WallEvent:FireClient(player, "Progress", {
		Zone = WallConfig.Groups[1].Name,
		GroupIndex = 1,
		PendingWins = 0,
	})
end

-- Initialize player session data
local function onPlayerAdded(player)
	PlayerProgress[player.UserId] = {
		GroupIndex = 1,
		WallIndex = 1,
		CurrentHP = WallConfig.GetMaxHP(1, 1),
		TotalWins = 0,
		PendingWins = 0,
	}
	task.delay(2, function()
		if PlayerProgress[player.UserId] then
			notifyNewWall(player)
			WallEvent:FireClient(player, "Progress", {
				Zone = WallConfig.Groups[1].Name,
				GroupIndex = 1,
				PendingWins = 0,
			})
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerProgress[player.UserId] = nil
	claimDebounce[player.UserId] = nil
end)

-- Rebirth resets everything, including unclaimed wins
RebirthEvent.OnServerEvent:Connect(function(player)
	local data = PlayerProgress[player.UserId]
	if data then
		data.GroupIndex = 1
		data.WallIndex = 1
		data.CurrentHP = WallConfig.GetMaxHP(1, 1)
		data.PendingWins = 0
		WallEvent:FireClient(player, "ResetProgress")
		notifyNewWall(player)
		WallEvent:FireClient(player, "Progress", {
			Zone = WallConfig.Groups[1].Name,
			GroupIndex = 1,
			PendingWins = 0,
		})
	end
end)

WallEvent.OnServerEvent:Connect(function(player, action, payload)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	if action == "DamageWall" then
		local group = WallConfig.Groups[data.GroupIndex]
		if not group then return end
		if data.WallIndex > #group.Healths then return end

		-- Verify the player is hitting THEIR current wall
		if typeof(payload) ~= "table" then return end
		if payload.Group ~= data.GroupIndex or payload.Wall ~= data.WallIndex then
			return
		end

		local damage = getSwordDamage(player)
		data.CurrentHP = math.max(0, data.CurrentHP - damage)

		if data.CurrentHP <= 0 then
			local brokenGroup = data.GroupIndex
			local brokenIndex = data.WallIndex
			data.WallIndex += 1

			WallEvent:FireClient(player, "BreakWall", {
				GroupIndex = brokenGroup,
				WallIndex = brokenIndex,
			})

			if data.WallIndex > #group.Healths then
				-- Zone finished! Bank the reward as unclaimed wins and
				-- AUTO-ADVANCE to the next zone. The player does NOT need
				-- to claim wins to keep going - claiming is their choice.
				data.PendingWins += (group.WinReward or 1)
				local nextGroup = data.GroupIndex + 1
				if nextGroup > #WallConfig.Groups then
					nextGroup = 1 -- loop back to the first zone after the last one
				end
				data.GroupIndex = nextGroup
				data.WallIndex = 1
				data.CurrentHP = WallConfig.GetMaxHP(nextGroup, 1)
				teleportToWall(player, nextGroup, 1)
				WallEvent:FireClient(player, "Progress", {
					Zone = WallConfig.Groups[nextGroup].Name,
					GroupIndex = nextGroup,
					PendingWins = data.PendingWins,
				})
			else
				data.CurrentHP = WallConfig.GetMaxHP(data.GroupIndex, data.WallIndex)
			end
			notifyNewWall(player)
		else
			-- Wall still standing: update the wall GUI with the new HP
			WallEvent:FireClient(player, "Damage", {
				GroupIndex = data.GroupIndex,
				WallIndex = data.WallIndex,
				HP = data.CurrentHP,
				MaxHP = WallConfig.GetMaxHP(data.GroupIndex, data.WallIndex),
			})
		end

	elseif action == "ClaimWin" then
		claimWin(player)
	end
end)

-- Win pads: claiming is the player's CHOICE. They can touch any time they
-- have unclaimed wins banked; claiming banks them and resets to Group 1.
for _, group in ipairs(wallFolder:GetChildren()) do
	for _, child in ipairs(group:GetChildren()) do
		if child.Name:find("WinsGroup") and child:IsA("BasePart") then
			child.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if player then
					local data = PlayerProgress[player.UserId]
					if data and data.PendingWins > 0 then
						claimWin(player)
					end
				end
			end)
		end
	end
end

return WallManager
