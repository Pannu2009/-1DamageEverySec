
-- DataStore + passive damage + rebirth + server-side sword damage.
-- Don;t touch this script unless you know what you're doing.

local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local DataStore = DataStoreService:GetDataStore("PlayerData")

local RebirthConfig = require(Rep.Shared:WaitForChild("RebirthConfig",30))
local SwordConfig = require(Rep.Shared:WaitForChild("SwordConfig"))

local Remotes = Rep:WaitForChild("Remotes")
local GuiRemote = Remotes:WaitForChild("EverySec")
local RebirthEvent = Remotes:WaitForChild("RebirthEvent")

local function getRebirthMulti(level)
	local data = RebirthConfig.Data[level]
	return data and data.Multi or 1
end

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

local function getSwordName(sword)
	if not sword then
		return SwordConfig.DefaultSword
	end

	local name = sword:GetAttribute("SwordName")
	if typeof(name) == "string" and SwordConfig.GetSword(name) then
		return name
	end

	if SwordConfig.GetSword(sword.Name) then
		return sword.Name
	end

	return SwordConfig.DefaultSword
end

local function getSwordMulti(player)
	return SwordConfig.GetMulti(getSwordName(getPlayerSword(player)))
end

local function updateSword(player, finalDamage, swordMulti, swordName)
	local function update(container)
		if not container then return end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsSword") == true or item.Name == "Sword" or item.Name == "sword") then
				item:SetAttribute("IsSword", true)
				item:SetAttribute("SwordName", swordName)
				item:SetAttribute("SwordMulti", swordMulti)
				item:SetAttribute("Damage", finalDamage)
			end
		end
	end

	update(player.Character)
	update(player:FindFirstChild("Backpack"))
end

local function updateStats(player)
	local stats = player:FindFirstChild("leaderstats")
	local utils = player:FindFirstChild("Utils")
	if not (stats and utils) then return end

	local wins = stats:FindFirstChild("Wins")
	local shards = stats:FindFirstChild("Shards")
	local damage = utils:FindFirstChild("Damage")
	local rebirth = utils:FindFirstChild("Rebirth")
	if not (wins and shards and damage and rebirth) then return end

	local rebirthMulti = getRebirthMulti(rebirth.Value)
	local swordName = getSwordName(getPlayerSword(player))
	local swordMulti = SwordConfig.GetMulti(swordName)

	local finalDamage = damage.Value * rebirthMulti * swordMulti

	updateSword(player, finalDamage, swordMulti, swordName)

	GuiRemote:FireClient(player, {
		Damage = damage.Value,
		RebirthMulti = rebirthMulti,
		SwordName = swordName,
		SwordMulti = swordMulti,
		FinalDamage = finalDamage,
	})
end

local function giveDefaultSword(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then return end
	if getPlayerSword(player) then
		updateStats(player)
		return
	end

	local template = ServerStorage:FindFirstChild(SwordConfig.DefaultModelName)
		or ServerStorage:FindFirstChild("Sword")

	if not template or not template:IsA("Tool") then
		warn("MainServer: ServerStorage.sword was not found as a Tool")
		return
	end

	local sword = template:Clone()
	sword.Name = "Sword"
	sword:SetAttribute("IsSword", true)
	sword:SetAttribute("SwordName", SwordConfig.DefaultSword)
	sword:SetAttribute("SwordMulti", SwordConfig.GetMulti(SwordConfig.DefaultSword))
	sword:SetAttribute("Damage", 1)
	sword.Parent = backpack

	updateStats(player)
end

local function setupPlayer(player)
	local oldStats = player:FindFirstChild("leaderstats")
	local oldUtils = player:FindFirstChild("Utils")
	if oldStats then oldStats:Destroy() end
	if oldUtils then oldUtils:Destroy() end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local utils = Instance.new("Folder")
	utils.Name = "Utils"
	utils.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = stats

	local shards = Instance.new("IntValue")
	shards.Name = "Shards"
	shards.Value = 0
	shards.Parent = stats

	local damage = Instance.new("NumberValue")
	damage.Name = "Damage"
	damage.Value = 1
	damage.Parent = utils

	local rebirth = Instance.new("IntValue")
	rebirth.Name = "Rebirth"
	rebirth.Value = 0
	rebirth.Parent = utils

	local shop = Instance.new("Folder")
	shop.Name = "Shop"
	shop.Parent = player

	local cosmeticsOwned = Instance.new("StringValue")
	cosmeticsOwned.Name = "Cosmetics"
	cosmeticsOwned.Value = ""
	cosmeticsOwned.Parent = shop

	local petsOwned = Instance.new("StringValue")
	petsOwned.Name = "Pets"
	petsOwned.Value = ""
	petsOwned.Parent = shop

	local equippedCosmetic = Instance.new("StringValue")
	equippedCosmetic.Name = "EquippedCosmetic"
	equippedCosmetic.Value = ""
	equippedCosmetic.Parent = shop

	local equippedPet = Instance.new("StringValue")
	equippedPet.Name = "EquippedPet"
	equippedPet.Value = ""
	equippedPet.Parent = shop

	local success, data = pcall(function()
		return DataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and typeof(data) == "table" then
		damage.Value = tonumber(data.Damage) or 1
		wins.Value = tonumber(data.Wins) or 0
		rebirth.Value = tonumber(data.Rebirths) or 0
		shards.Value = tonumber(data.Shards) or 0
		cosmeticsOwned.Value = typeof(data.Cosmetics) == "string" and data.Cosmetics or ""
		petsOwned.Value = typeof(data.Pets) == "string" and data.Pets or ""
		equippedCosmetic.Value = typeof(data.EquippedCosmetic) == "string" and data.EquippedCosmetic or ""
		equippedPet.Value = typeof(data.EquippedPet) == "string" and data.EquippedPet or ""
	end

	damage.Changed:Connect(function()
		updateStats(player)
	end)
	wins.Changed:Connect(function()
		updateStats(player)
	end)
	rebirth.Changed:Connect(function()
		updateStats(player)
	end)

	local function onCharacterAdded()
		task.wait(0.25)
		giveDefaultSword(player)
		updateStats(player)
	end

	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		task.spawn(onCharacterAdded)
	end
	
	local oldShop = player:FindFirstChild("Shop")
	if oldShop and oldShop ~= shop then
		oldShop:Destroy()
	end
end

local function savePlayer(player)
	local stats = player:FindFirstChild("leaderstats")
	local utils = player:FindFirstChild("Utils")
	local shop = player:FindFirstChild("Shop")
	if not (stats and utils and shop) then return end

	local wins = stats:FindFirstChild("Wins")
	local shards = stats:FindFirstChild("Shards")
	local damage = utils:FindFirstChild("Damage")
	local rebirth = utils:FindFirstChild("Rebirth")
	local cosmetics = shop:FindFirstChild("Cosmetics")
	local pets = shop:FindFirstChild("Pets")
	local equippedCosmetic = shop:FindFirstChild("EquippedCosmetic")
	local equippedPet = shop:FindFirstChild("EquippedPet")
	if not (wins and shards and damage and rebirth and cosmetics and pets and equippedCosmetic and equippedPet) then return end

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
		DataStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("Failed to save " .. player.Name .. ": " .. tostring(err))
	end
end

RebirthEvent.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	local utils = player:FindFirstChild("Utils")
	if not (stats and utils) then return end

	local wins = stats:FindFirstChild("Wins")
	local shards = stats:FindFirstChild("Shards")
	local rebirth = utils:FindFirstChild("Rebirth")
	local damage = utils:FindFirstChild("Damage")
	if not (wins and shards and rebirth and damage) then return end

	local nextLevel = rebirth.Value + 1
	local nextData = RebirthConfig.Data[nextLevel]

	if not nextData then
		RebirthEvent:FireClient(player, false, "Max Rebirth Reached")
		return
	end

	if wins.Value < nextData.WinsReq then
		RebirthEvent:FireClient(player, false, "Not enough wins")
		return
	end

	wins.Value -= nextData.WinsReq
	rebirth.Value += 1
	damage.Value = 1

	updateStats(player)
	RebirthEvent:FireClient(
		player,
		true,
		"Rebirthed! You are now x" .. tostring(getRebirthMulti(rebirth.Value))
	)
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end
Players.PlayerRemoving:Connect(savePlayer)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)


task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local utils = player:FindFirstChild("Utils")
			local damage = utils and utils:FindFirstChild("Damage")
			local rebirth = utils and utils:FindFirstChild("Rebirth")
			if damage and rebirth then
				damage.Value += 1 * getRebirthMulti(rebirth.Value) * getSwordMulti(player)
			end
		end
	end
end)


