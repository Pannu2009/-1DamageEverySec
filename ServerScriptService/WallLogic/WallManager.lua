-- WallManager
-- Per-player wall progression stays client-visible, but damage is server validated.
-- Completing a group does NOT create pending/stacked rewards.
-- The reward for claiming is simply the group/level being claimed.

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

local MAX_HIT_DISTANCE = 18
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
	if not sword then return 1 end

	local damage = sword:GetAttribute("Damage")
	if typeof(damage) == "number" and damage > 0 then
		return damage
	end

	local swordName = sword:GetAttribute("SwordName")
	return typeof(swordName) == "string" and SwordConfig.GetMulti(swordName) or 1
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
	})
end

local function notifyNewWall(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end
	local maxHp = WallConfig.GetMaxHp(data.GroupIndex, data.WallIndex)
	if maxHp <= 0 then return end

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

local function claimGroup(player, groupIndex)
	local userId = player.UserId
	if claimDebounce[userId] then return end

	local data = PlayerProgress[userId]
	if not data then return end

	groupIndex = tonumber(groupIndex)
	if not groupIndex or groupIndex < 1 or groupIndex > #WallConfig.Groups then return end

	-- You can only claim a group after reaching past its final wall.
	-- No old groups are added together: the claimed reward is exactly the group level.
	if data.GroupIndex <= groupIndex then
		return
	end

	claimDebounce[userId] = true
	task.delay(1.5, function()
		claimDebounce[userId] = nil
	end)

	local stats = player:FindFirstChild("leaderstats")
	local wins = stats and stats:FindFirstChild("Wins")
	if not wins then return end

	wins.Value += groupIndex
	teleportToSpawn(player)
	resetProgress(player)
end

local function onPlayerAdded(player)
	PlayerProgress[player.UserId] = {
		GroupIndex = 1,
		WallIndex = 1,
		CurrentHP = WallConfig.GetMaxHp(1, 1),
	}

	task.delay(1, function()
		if PlayerProgress[player.UserId] then
			notifyNewWall(player)
			notifyProgress(player)
		end
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
		if groupIndex ~= data.GroupIndex or wallIndex ~= data.WallIndex then return end

		local wall = getWall(data.GroupIndex, data.WallIndex)
		if not wall then return end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if (hrp.Position - wall.Position).Magnitude > MAX_HIT_DISTANCE then return end

		local now = os.clock()
		local lastHit = hitDebounce[player.UserId] or 0
		if now - lastHit < SERVER_HIT_COOLDOWN then return end
		hitDebounce[player.UserId] = now

		local sword = getPlayerSword(player)
		if not sword or not sword:IsA("Tool") or sword.Parent ~= char then return end

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
				-- Finished this group. The next group becomes the player's level.
				-- There is NO PendingWins value and no stacked reward.
				local nextGroup = data.GroupIndex + 1
				if WallConfig.Groups[nextGroup] then
					data.GroupIndex = nextGroup
					data.WallIndex = 1
					data.CurrentHP = WallConfig.GetMaxHp(nextGroup, 1)
				else
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
		claimGroup(player, payload)
	end
end)

-- Every claim pad awards ONLY its own group number.
local function connectWinPad(part)
	if not part:IsA("BasePart") then return end
	local groupIndex = tonumber(part.Name:match("^WinsGroup(%d+)$"))
	if not groupIndex then return end

	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			claimGroup(player, groupIndex)
		end
	end)
end

for _, group in ipairs(wallFolder:GetChildren()) do
	for _, child in ipairs(group:GetChildren()) do
		connectWinPad(child)
	end
end

return {}
