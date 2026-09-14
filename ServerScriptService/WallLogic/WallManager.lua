-- WallManager
-- Server-authoritative wall progression and win claiming.
-- Players may keep progressing without claiming their pending wins.
-- Touching a WinsGroup pad banks the pending wins and returns the player to spawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WallConfig = require(ReplicatedStorage.Shared:WaitForChild("WallConfig"))
local SwordConfig = require(ReplicatedStorage.Shared:WaitForChild("SwordConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WallEvent = Remotes:WaitForChild("WallEvent")
local RebirthEvent = Remotes:WaitForChild("RebirthEvent")

local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

local PlayerProgress = {}
local claimDebounce = {}
local hitDebounce = {}

local MAX_HIT_DISTANCE = 16
local SERVER_HIT_COOLDOWN = 0.35

local function getPlayerSword(player)
	local char = player.Character
	local backpack = player:FindFirstChild("Backpack")

	local function find(container)
		if not container then return nil end

		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("IsSword") == true then
				return item
			end
		end

		return container:FindFirstChild("Sword") or container:FindFirstChild("sword")
	end

	return find(char) or find(backpack)
end

local function getSwordDamage(player)
	local sword = getPlayerSword(player)
	if not sword then
		return 1
	end

	local damage = sword:GetAttribute("Damage")
	if typeof(damage) == "number" and damage > 0 then
		return damage
	end

	local swordName = sword:GetAttribute("SwordName")
	if typeof(swordName) == "string" then
		return SwordConfig.GetMulti(swordName)
	end

	return 1
end

local function getWall(groupIndex, wallIndex)
	local groupFolder = wallFolder:FindFirstChild("Group" .. groupIndex)
	return groupFolder and groupFolder:FindFirstChild("Wall" .. wallIndex)
end

local function notifyProgress(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	local group = WallConfig.Groups[data.GroupIndex]
	if not group then return end

	WallEvent:FireClient(player, "Progress", {
		Zone = group.Name,
		GroupIndex = data.GroupIndex,
		WallIndex = data.WallIndex,
		PendingWins = data.PendingWins,
	})
end

local function notifyNewWall(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	local maxHp = WallConfig.GetMaxHp(data.GroupIndex, data.WallIndex)
	if maxHp <= 0 then
		return
	end

	WallEvent:FireClient(player, "NewWall", {
		GroupIndex = data.GroupIndex,
		WallIndex = data.WallIndex,
		HP = data.CurrentHP,
		MaxHP = maxHp,
	})
end

local function resetProgress(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	data.GroupIndex = 1
	data.WallIndex = 1
	data.CurrentHP = WallConfig.GetMaxHp(1, 1)
	data.PendingWins = 0

	WallEvent:FireClient(player, "ResetProgress")
	notifyNewWall(player)
	notifyProgress(player)
end

local function teleportToSpawn(player)
	local spawnLoc = workspace:FindFirstChild("SpawnLocation")
	local char = player.Character
	if char and spawnLoc then
		char:PivotTo(CFrame.new(spawnLoc.Position + Vector3.new(0, 3, 0)))
	end
end

local function claimWin(player)
	local userId = player.UserId
	if claimDebounce[userId] then return end
	claimDebounce[userId] = true
	task.delay(1.5, function()
		claimDebounce[userId] = nil
	end)

	local data = PlayerProgress[userId]
	if not data or data.PendingWins <= 0 then
		return
	end

	local stats = player:FindFirstChild("leaderstats")
	local wins = stats and stats:FindFirstChild("Wins")
	if not wins then return end

	wins.Value += data.PendingWins
	data.TotalWins += data.PendingWins

	teleportToSpawn(player)
	resetProgress(player)
end

local function onPlayerAdded(player)
	PlayerProgress[player.UserId] = {
		GroupIndex = 1,
		WallIndex = 1,
		CurrentHP = WallConfig.GetMaxHp(1, 1),
		TotalWins = 0,
		PendingWins = 0,
	}

	task.delay(1, function()
		if not PlayerProgress[player.UserId] then return end
		notifyNewWall(player)
		notifyProgress(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	PlayerProgress[userId] = nil
	claimDebounce[userId] = nil
	hitDebounce[userId] = nil
end)

-- Rebirth is intentionally connected here too so wall progress resets
-- at the same time as the player's rebirth.
RebirthEvent.OnServerEvent:Connect(function(player)
	resetProgress(player)
end)

WallEvent.OnServerEvent:Connect(function(player, action, payload)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	if action == "DamageWall" then
		if typeof(payload) ~= "table" then return end

		local groupIndex = tonumber(payload.Group)
		local wallIndex = tonumber(payload.Wall)
		if not groupIndex or not wallIndex then return end

		-- The client may only request damage against its current wall.
		if groupIndex ~= data.GroupIndex or wallIndex ~= data.WallIndex then
			return
		end

		local group = WallConfig.Groups[data.GroupIndex]
		if not group then return end
		if data.WallIndex > WallConfig.GetWallCount(data.GroupIndex) then return end

		local wall = getWall(data.GroupIndex, data.WallIndex)
		if not wall then return end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Server-side distance validation.
		if (hrp.Position - wall.Position).Magnitude > MAX_HIT_DISTANCE then
			return
		end

		-- Server-side rate limit so the client cannot spam the RemoteEvent.
		local now = os.clock()
		local lastHit = hitDebounce[player.UserId] or 0
		if now - lastHit < SERVER_HIT_COOLDOWN then
			return
		end
		hitDebounce[player.UserId] = now

		local sword = getPlayerSword(player)
		if not sword or not sword:IsA("Tool") then return end

		local damage = getSwordDamage(player)
		data.CurrentHP = math.max(0, data.CurrentHP - damage)

		if data.CurrentHP <= 0 then
			local brokenGroup = data.GroupIndex
			local brokenWall = data.WallIndex

			WallEvent:FireClient(player, "BreakWall", {
				GroupIndex = brokenGroup,
				WallIndex = brokenWall,
			})

			data.WallIndex += 1

			if data.WallIndex > WallConfig.GetWallCount(data.GroupIndex) then
				-- Zone completed. The reward is now UNCLAIMED.
				-- Do NOT teleport the player: they can choose to continue
				-- physically into the next zone.
				data.PendingWins += WallConfig.GetWinReward(data.GroupIndex)

				local nextGroup = data.GroupIndex + 1
				if WallConfig.Groups[nextGroup] then
					data.GroupIndex = nextGroup
					data.WallIndex = 1
					data.CurrentHP = WallConfig.GetMaxHp(nextGroup, 1)
				else
					-- Final configured zone reached. Stay at the final zone;
					-- this leaves the end-game/boss expansion open for later.
					data.WallIndex = WallConfig.GetWallCount(data.GroupIndex)
					data.CurrentHP = 0
				end
			else
				data.CurrentHP = WallConfig.GetMaxHp(data.GroupIndex, data.WallIndex)
			end

			notifyProgress(player)
			notifyNewWall(player)
		else
			WallEvent:FireClient(player, "Damage", {
				GroupIndex = data.GroupIndex,
				WallIndex = data.WallIndex,
				HP = data.CurrentHP,
				MaxHP = WallConfig.GetMaxHp(data.GroupIndex, data.WallIndex),
			})
		end

	elseif action == "ClaimWin" then
		claimWin(player)
	end
end)

-- Win pads: touching one is the player's choice to bank pending wins.
local function connectWinPad(part)
	if not part:IsA("BasePart") then return end

	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			claimWin(player)
		end
	end)
end

for _, group in ipairs(wallFolder:GetChildren()) do
	for _, child in ipairs(group:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^WinsGroup%d+$") then
			connectWinPad(child)
		end
	end
end

return WallManager
