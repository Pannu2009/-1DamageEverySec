local DataStoreService = game:GetService("DataStoreService")
local DataStore = {
	playerData = DataStoreService:GetDataStore("PlayerData"),
	wallProgress = DataStoreService:GetDataStore("WallProgress"),
}

local DEFAULTS = {
	Wins = 0,
	Damage = 1,
	Rebirths = 0,
	Shards = 0,
	Cosmetics = "",
	Pets = "",
	EquippedCosmetic = "",
	EquippedPet = "",
}

local playerData = {}

function playerData:Load(player)
	local success, data = pcall(function()
		return DataStore.playerData:GetAsync("Player_" .. player.UserId)
	end)

	if not success then
		warn("DataHandler: failed to load " .. player.Name .. ": " .. tostring(data))
		return nil
	end

	if typeof(data) ~= "table" then
		return table.clone(DEFAULTS)
	end

	local merged = table.clone(DEFAULTS)
	for key, value in pairs(data) do
		if DEFAULTS[key] ~= nil then
			merged[key] = value
		end
	end
	return merged
end

function playerData:Save(player)
	local stats = player:FindFirstChild("leaderstats")
	local utils = player:FindFirstChild("Utils")
	local shop = player:FindFirstChild("Shop")
	if not (stats and utils and shop) then return false end

	local wins = stats:FindFirstChild("Wins")
	local shards = stats:FindFirstChild("Shards")
	local damage = utils:FindFirstChild("Damage")
	local rebirth = utils:FindFirstChild("Rebirth")
	local cosmetics = shop:FindFirstChild("Cosmetics")
	local pets = shop:FindFirstChild("Pets")
	local equippedCosmetic = shop:FindFirstChild("EquippedCosmetic")
	local equippedPet = shop:FindFirstChild("EquippedPet")
	if not (wins and shards and damage and rebirth and cosmetics and pets and equippedCosmetic and equippedPet) then
		return false
	end

	local data = {
		Wins = wins.Value,
		Damage = damage.Value,
		Rebirths = rebirth.Value,
		Shards = shards.Value,
		Cosmetics = cosmetics.Value,
		Pets = pets.Value,
		EquippedCosmetic = equippedCosmetic.Value,
		EquippedPet = equippedPet.Value,
	}

	local success, err = pcall(function()
		DataStore.playerData:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("DataHandler: failed to save " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function playerData:SaveWallProgress(player, groupIndex, wallIndex, infinityLevel, overflow)
	local success, err = pcall(function()
		DataStore.wallProgress:SetAsync("Progress_" .. player.UserId, {
			GroupIndex = groupIndex,
			WallIndex = wallIndex,
			InfinityLevel = infinityLevel,
			Overflow = overflow or 0,
		})
	end)

	if not success then
		warn("DataHandler: failed to save wall progress for " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function playerData:LoadWallProgress(player)
	local success, saved = pcall(function()
		return DataStore.wallProgress:GetAsync("Progress_" .. player.UserId)
	end)

	if not success then
		warn("DataHandler: failed to load wall progress for " .. player.Name .. ": " .. tostring(saved))
		return nil
	end

	if typeof(saved) ~= "table" then
		return nil
	end
	return saved
end

function playerData:SaveExternal(player)
	
end


local Players = game:GetService("Players")

local AUTOSAVE_INTERVAL = 120 -- seconds between autosaves

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			playerData:Save(player)
		end
	end
end)

return playerData