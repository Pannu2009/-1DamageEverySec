local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local WallConfig = require(ReplicatedStorage.Shared:WaitForChild("WallsConfig"))
local SwordConfig = require(ReplicatedStorage.Shared:WaitForChild("SwordConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WallEvent = Remotes:WaitForChild("WallEvent")

local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

local ProgressStore = DataStoreService:GetDataStore("WallProgress")

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

	local zoneName = group.Name
	if group.IsInfinity and data.InfinityLevel > 1 then
		zoneName = zoneName .. " x" .. data.InfinityLevel
	end

	WallEvent:FireClient(player, "Progress", {
		Zone = zoneName,
		GroupIndex = data.GroupIndex,
		WallIndex = data.WallIndex,
		Total = #WallConfig.Groups,
		InfinityLevel = data.InfinityLevel,
	})
end

local function notifyNewWall(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end
	local maxHp = WallConfig.GetEffectiveMaxHp(data.GroupIndex, data.WallIndex, data.InfinityLevel)
	if maxHp <= 0 then return end

	WallEvent:FireClient(player, "NewWall", {
		GroupIndex = data.GroupIndex,
		WallIndex = data.WallIndex,
		HP = data.CurrentHP,
		MaxHP = maxHp,
		Overflow = data.Overflow or 0,
	})
end

local function resetProgress(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	data.GroupIndex = 1
	data.WallIndex = 1
	data.InfinityLevel = 1
	data.Overflow = 0
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

local teleportDebounce = {}

local function teleportToZone(player)
	local userId = player.UserId
	if teleportDebounce[userId] then return end

	local data = PlayerProgress[userId]
	if not data then return end

	local groupFolder = wallFolder:FindFirstChild("Group" .. data.GroupIndex)
	local wall1 = groupFolder and groupFolder:FindFirstChild("Wall1")
	if not wall1 then return end

	teleportDebounce[userId] = true
	task.delay(5, function()
		teleportDebounce[userId] = nil
	end)

	local char = player.Character
	if char then
		char:PivotTo(CFrame.new(wall1.Position.X + 8, 3, wall1.Position.Z))
	end
end

local function claimGroup(player, groupIndex)
	local userId = player.UserId
	if claimDebounce[userId] then return end

	local data = PlayerProgress[userId]
	if not data then return end

	groupIndex = tonumber(groupIndex)
	if not groupIndex or groupIndex < 1 or groupIndex > #WallConfig.Groups then return end

	local isInfinity = WallConfig.IsInfinityGroup(groupIndex)
	if isInfinity then
		-- Infinity pad: must be in the Infinity Zone with at least one full loop completed
		if data.GroupIndex ~= groupIndex or data.InfinityLevel <= 1 then
			return
		end
	elseif data.GroupIndex <= groupIndex then
		return
	end

	claimDebounce[userId] = true
	task.delay(1.5, function()
		claimDebounce[userId] = nil
	end)

	local stats = player:FindFirstChild("leaderstats")
	local wins = stats and stats:FindFirstChild("Wins")
	if not wins then return end

	wins.Value += WallConfig.GetInfinityReward(groupIndex, data.InfinityLevel)
	teleportToSpawn(player)
	resetProgress(player)
end

local function loadProgress(userId)
	local success, saved = pcall(function()
		return ProgressStore:GetAsync("Progress_" .. userId)
	end)
	if not success or typeof(saved) ~= "table" then return nil end
	return saved
end

local function saveProgress(player)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	local success, err = pcall(function()
		ProgressStore:SetAsync("Progress_" .. player.UserId, {
			GroupIndex = data.GroupIndex,
			WallIndex = data.WallIndex,
			InfinityLevel = data.InfinityLevel,
			Overflow = data.Overflow or 0,
		})
	end)
	if not success then
		warn("WallManager: failed to save progress for " .. player.Name .. ": " .. tostring(err))
	end
end

local function onPlayerAdded(player)
	local saved = loadProgress(player.UserId)

	local groupIndex = 1
	local wallIndex = 1
	local infinityLevel = 1

	if saved then
		local sGroup = tonumber(saved.GroupIndex) or 1
		local sWall = tonumber(saved.WallIndex) or 1
		local sInfinity = tonumber(saved.InfinityLevel) or 1

		if sGroup >= 1 and sGroup <= #WallConfig.Groups then
			groupIndex = sGroup
			wallIndex = math.clamp(sWall, 1, WallConfig.GetWallCount(groupIndex))
			infinityLevel = math.max(sInfinity, 1)
		end
	end

	PlayerProgress[player.UserId] = {
		GroupIndex = groupIndex,
		WallIndex = wallIndex,
		InfinityLevel = infinityLevel,
		CurrentHP = WallConfig.GetEffectiveMaxHp(groupIndex, wallIndex, infinityLevel),
		Overflow = math.max(tonumber(saved and saved.Overflow) or 0, 0),
	}

	task.spawn(function()
		local utils = player:WaitForChild("Utils", 15)
		local rebirth = utils and utils:WaitForChild("Rebirth", 10)
		if rebirth then
			rebirth.Changed:Connect(function()
				resetProgress(player)
			end)
		end
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if PlayerProgress[player.UserId] then
			notifyNewWall(player)
			notifyProgress(player)
		end
	end)

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
	saveProgress(player)
	local userId = player.UserId
	PlayerProgress[userId] = nil
	claimDebounce[userId] = nil
	hitDebounce[userId] = nil
	teleportDebounce[userId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveProgress(player)
	end
end)

local function applyWallDamage(player, damage)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- combine any stored overflow with this hit
	local remaining = damage + (data.Overflow or 0)
	data.Overflow = 0

	local guardCount = 0
	local advanced = false

	-- overflow loop: leftover damage keeps hitting the next wall
	while remaining > 0 and guardCount < 200 do
		guardCount += 1

		local wall = getWall(data.GroupIndex, data.WallIndex)
		if not wall then break end

		-- can only damage walls within reach; if the next wall is too far
		-- (e.g. next group's zone), store the leftover for the next hit
		if (hrp.Position - wall.Position).Magnitude > MAX_HIT_DISTANCE then
			data.Overflow = remaining
			remaining = 0
			break
		end

		if remaining < data.CurrentHP then
			-- wall survives, absorb the hit
			data.CurrentHP -= remaining
			remaining = 0
			WallEvent:FireClient(player, "Damage", {
				GroupIndex = data.GroupIndex,
				WallIndex = data.WallIndex,
				HP = data.CurrentHP,
				MaxHP = WallConfig.GetEffectiveMaxHp(data.GroupIndex, data.WallIndex, data.InfinityLevel),
			})
		else
			-- wall breaks, leftover carries to the next wall
			remaining -= data.CurrentHP

			WallEvent:FireClient(player, "BreakWall", {
				GroupIndex = data.GroupIndex,
				WallIndex = data.WallIndex,
			})

			data.WallIndex += 1
			advanced = true

			if data.WallIndex > WallConfig.GetWallCount(data.GroupIndex) then
				if WallConfig.IsInfinityGroup(data.GroupIndex) then
					-- Infinity Zone: loop forever with scaling HP
					data.InfinityLevel += 1
					data.WallIndex = 1
				else
					local nextGroup = data.GroupIndex + 1
					data.GroupIndex = nextGroup
					data.WallIndex = 1
				end
			end
			data.CurrentHP = WallConfig.GetEffectiveMaxHp(data.GroupIndex, data.WallIndex, data.InfinityLevel)
		end
	end

	-- safety net: if the guard limit was hit, keep the leftover instead of losing it
	if remaining > 0 then
		data.Overflow = (data.Overflow or 0) + remaining
		remaining = 0
	end

	if advanced then
		notifyProgress(player)
		notifyNewWall(player)
	elseif (data.Overflow or 0) > 0 then
		-- leftover was stored because the next wall is out of reach;
		-- update the HUD so the player can see the stored damage
		WallEvent:FireClient(player, "Damage", {
			GroupIndex = data.GroupIndex,
			WallIndex = data.WallIndex,
			HP = data.CurrentHP,
			MaxHP = WallConfig.GetEffectiveMaxHp(data.GroupIndex, data.WallIndex, data.InfinityLevel),
			Overflow = data.Overflow,
		})
	end
end

WallEvent.OnServerEvent:Connect(function(player, action, payload)
	local data = PlayerProgress[player.UserId]
	if not data then return end

	if action == "DamageWall" then
		if typeof(payload) ~= "table" then return end

		local groupIndex = tonumber(payload.Group)
		local wallIndex = tonumber(payload.Wall)
		if not groupIndex or not wallIndex then return end
		if groupIndex ~= data.GroupIndex or wallIndex ~= data.WallIndex then return end

		local now = os.clock()
		local lastHit = hitDebounce[player.UserId] or 0
		if now - lastHit < SERVER_HIT_COOLDOWN then return end
		hitDebounce[player.UserId] = now

		local char = player.Character
		local sword = getPlayerSword(player)
		if not sword or not sword:IsA("Tool") or sword.Parent ~= char then return end

		applyWallDamage(player, getSwordDamage(player))

	elseif action == "ClaimWin" then
		claimGroup(player, payload)

	elseif action == "TeleportToZone" then
		teleportToZone(player)
	end
end)

local petBindable = Instance.new("BindableEvent")
petBindable.Name = "PetDamage"
petBindable.Parent = script.Parent
petBindable.Event:Connect(function(player, damage)
	applyWallDamage(player, damage)
end)

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
