--:;  convert to shards, sword cosmetics, RNG chests,
-- and auto-attack pet companions. 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ShopConfig = require(ReplicatedStorage.Shared:WaitForChild("ShopConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopEvent = Remotes:WaitForChild("ShopEvent")

local PetDamage = ServerScriptService.Walls:WaitForChild("PetDamage", 30)

local activePets = {}
local debounce = {}

-- ===== helpers =====

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

local function getPlayerDamage(player)
	local sword = getPlayerSword(player)
	local dmg = sword and sword:GetAttribute("Damage")
	if typeof(dmg) == "number" and dmg > 0 then
		return dmg
	end
	local utils = player:FindFirstChild("Utils")
	local d = utils and utils:FindFirstChild("Damage")
	return (d and d.Value) or 1
end

local function getShopValue(player, name)
	local shop = player:FindFirstChild("Shop")
	local sv = shop and shop:FindFirstChild(name)
	return sv
end

local function getOwned(player, listName)
	local sv = getShopValue(player, listName)
	if not sv or sv.Value == "" then return {} end
	local out = {}
	for part in string.gmatch(sv.Value, "[^,]+") do
		table.insert(out, part)
	end
	return out
end

local function setOwned(player, listName, list)
	local sv = getShopValue(player, listName)
	if sv then sv.Value = table.concat(list, ",") end
end

local function owns(player, listName, itemName)
	return table.find(getOwned(player, listName), itemName) ~= nil
end

local function notify(player, message)
	local stats = player:FindFirstChild("leaderstats")
	local utils = player:FindFirstChild("Utils")
	ShopEvent:FireClient(player, "Update", {
		Wins = stats and stats:FindFirstChild("Wins") and stats.Wins.Value or 0,
		Shards = stats and stats:FindFirstChild("Shards") and stats.Shards.Value or 0,
		Cosmetics = getOwned(player, "Cosmetics"),
		EquippedCosmetic = (getShopValue(player, "EquippedCosmetic") and getShopValue(player, "EquippedCosmetic").Value) or "",
		Pets = getOwned(player, "Pets"),
		EquippedPet = (getShopValue(player, "EquippedPet") and getShopValue(player, "EquippedPet").Value) or "",
		Message = message,
	})
end

local function applyCosmetic(player, cosmetic)
	local sword = getPlayerSword(player)
	if not sword then return end
	for _, d in ipairs(sword:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Color = cosmetic.Color
		end
	end
end

local function reapplyEquippedCosmetic(player)
	local sv = getShopValue(player, "EquippedCosmetic")
	local cosmetic = sv and ShopConfig.GetCosmetic(sv.Value)
	if cosmetic then
		applyCosmetic(player, cosmetic)
	end
end


local function removePet(player)
	local entry = activePets[player.UserId]
	if entry then
		if entry.Model then
			entry.Model.Parent = nil
		end
		activePets[player.UserId] = nil
	end
end

local function spawnPet(player, petConfig)
	removePet(player)

	local model = Instance.new("Model")
	model.Name = petConfig.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(petConfig.Size, petConfig.Size, petConfig.Size)
	body.Color = petConfig.Color
	body.Material = Enum.Material.Neon
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.Parent = model
	model.PrimaryPart = body

	local bb = Instance.new("BillboardGui")
	bb.Name = "PetLabel"
	bb.Size = UDim2.new(0, 120, 0, 24)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 100
	bb.Parent = body

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.4
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Text = petConfig.Name
	tl.Parent = bb

	model.Parent = workspace
	activePets[player.UserId] = {Model = model, Config = petConfig}

	task.spawn(function()
		while activePets[player.UserId] and activePets[player.UserId].Config == petConfig do
			task.wait(petConfig.AttackInterval)
			local entry2 = activePets[player.UserId]
			if not entry2 or entry2.Config ~= petConfig then break end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and PetDamage then
				PetDamage:Fire(player, getPlayerDamage(player) * petConfig.DamagePercent)
			end
		end
	end)
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for userId, entry in pairs(activePets) do
		local player = Players:GetPlayerByUserId(userId)
		local char = player and player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and entry.Model and entry.Model.Parent then
			local bob = math.sin(t * 3 + userId) * 0.5
			entry.Model:PivotTo(hrp.CFrame * CFrame.new(3, 2.5 + bob, 2))
		end
	end
end)


local function tryGrantRandom(player, pool, listName, resultType)
	local owned = getOwned(player, listName)
	local available = {}
	for _, item in ipairs(pool) do
		if not table.find(owned, item.Name) then
			table.insert(available, item)
		end
	end
	if #available == 0 then return nil end

	local chosen = available[math.random(#available)]
	table.insert(owned, chosen.Name)
	setOwned(player, listName, owned)
	return {Type = resultType, Name = chosen.Name}
end

local function rollChest(player, chest)
	local roll = math.random()
	local result = nil

	if roll < chest.PetChance then
		result = tryGrantRandom(player, ShopConfig.Pets, "Pets", "Pet")
	elseif roll < chest.PetChance + chest.CosmeticChance then
		result = tryGrantRandom(player, ShopConfig.Cosmetics, "Cosmetics", "Cosmetic")
	end

	if not result then
		local stats = player:FindFirstChild("leaderstats")
		local shards = stats and stats:FindFirstChild("Shards")
		local amount = math.random(chest.Shards[1], chest.Shards[2])
		if shards then shards.Value += amount end
		result = {Type = "Shards", Amount = amount}
	end

	return result
end

local function onPlayerAdded(player)
	local shop = player:WaitForChild("Shop", 30)
	if not shop then return end

	player.CharacterAdded:Connect(function()
		task.delay(0.6, function()
			if player.Parent then
				reapplyEquippedCosmetic(player)
			end
		end)
	end)
	if player.Character then
		task.delay(0.6, function()
			if player.Parent then
				reapplyEquippedCosmetic(player)
			end
		end)
	end

	local petSv = shop:FindFirstChild("EquippedPet")
	if petSv and petSv.Value ~= "" then
		local petConfig = ShopConfig.GetPet(petSv.Value)
		if petConfig and owns(player, "Pets", petConfig.Name) then
			spawnPet(player, petConfig)
		end
	end

	task.delay(1, function()
		if player.Parent then notify(player) end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	removePet(player)
	debounce[player.UserId] = nil
end)


local function guard(player)
	if debounce[player.UserId] then return false end
	debounce[player.UserId] = true
	task.delay(0.4, function()
		debounce[player.UserId] = nil
	end)
	return true
end

ShopEvent.OnServerEvent:Connect(function(player, action, payload)
	if typeof(action) ~= "string" then return end
	if payload ~= nil and typeof(payload) ~= "table" then return end

	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	local wins = stats:FindFirstChild("Wins")
	local shards = stats:FindFirstChild("Shards")
	if not (wins and shards) then return end

	if not player:FindFirstChild("Shop") then return end

	if action == "Refresh" then
		notify(player)

	elseif action == "Convert" then
		if not guard(player) then return end
		local amount = math.floor(tonumber(payload and payload.Amount) or 0)
		if payload and payload.All then
			amount = wins.Value
		end
		if amount < ShopConfig.MinConvert then
			ShopEvent:FireClient(player, "Error", "Minimum convert is " .. ShopConfig.MinConvert .. " wins")
			return
		end
		if wins.Value < amount then
			ShopEvent:FireClient(player, "Error", "Not enough wins")
			return
		end
		wins.Value -= amount
		shards.Value += amount * ShopConfig.ConvertRate
		notify(player, "+" .. (amount * ShopConfig.ConvertRate) .. " shards")

	elseif action == "BuyCosmetic" then
		if not guard(player) then return end
		local name = payload and payload.Name
		local cosmetic = typeof(name) == "string" and ShopConfig.GetCosmetic(name)
		if not cosmetic then return end
		if owns(player, "Cosmetics", cosmetic.Name) then
			ShopEvent:FireClient(player, "Error", "Already owned")
			return
		end
		if wins.Value < cosmetic.Cost then
			ShopEvent:FireClient(player, "Error", "Not enough wins")
			return
		end
		wins.Value -= cosmetic.Cost
		local owned = getOwned(player, "Cosmetics")
		table.insert(owned, cosmetic.Name)
		setOwned(player, "Cosmetics", owned)
		notify(player, "Bought " .. cosmetic.Name)

	elseif action == "EquipCosmetic" then
		if not guard(player) then return end
		local name = payload and payload.Name
		local sv = getShopValue(player, "EquippedCosmetic")
		if not sv then return end
		if name == "" or name == nil then
			sv.Value = ""
			notify(player, "Cosmetic removed")
			return
		end
		local cosmetic = typeof(name) == "string" and ShopConfig.GetCosmetic(name)
		if not cosmetic or not owns(player, "Cosmetics", cosmetic.Name) then
			ShopEvent:FireClient(player, "Error", "You don't own that")
			return
		end
		sv.Value = cosmetic.Name
		applyCosmetic(player, cosmetic)
		notify(player, "Equipped " .. cosmetic.Name)

	elseif action == "OpenChest" then
		if not guard(player) then return end
		local name = payload and payload.Name
		local chest = typeof(name) == "string" and ShopConfig.GetChest(name)
		if not chest then return end
		if wins.Value < chest.Cost then
			ShopEvent:FireClient(player, "Error", "Not enough wins")
			return
		end
		wins.Value -= chest.Cost
		local result = rollChest(player, chest)
		notify(player)
		ShopEvent:FireClient(player, "ChestResult", {
			Chest = chest.Name,
			Type = result.Type,
			Name = result.Name,
			Amount = result.Amount,
		})

	elseif action == "BuyPet" then
		if not guard(player) then return end
		local name = payload and payload.Name
		local petConfig = typeof(name) == "string" and ShopConfig.GetPet(name)
		if not petConfig then return end
		if owns(player, "Pets", petConfig.Name) then
			ShopEvent:FireClient(player, "Error", "Already owned")
			return
		end
		if wins.Value < petConfig.Cost then
			ShopEvent:FireClient(player, "Error", "Not enough wins")
			return
		end
		wins.Value -= petConfig.Cost
		local owned = getOwned(player, "Pets")
		table.insert(owned, petConfig.Name)
		setOwned(player, "Pets", owned)
		notify(player, "Bought " .. petConfig.Name)

	elseif action == "EquipPet" then
		if not guard(player) then return end
		local name = payload and payload.Name
		local sv = getShopValue(player, "EquippedPet")
		if not sv then return end
		if name == "" or name == nil then
			sv.Value = ""
			removePet(player)
			notify(player, "Pet unequipped")
			return
		end
		local petConfig = typeof(name) == "string" and ShopConfig.GetPet(name)
		if not petConfig or not owns(player, "Pets", petConfig.Name) then
			ShopEvent:FireClient(player, "Error", "You don't own that pet")
			return
		end
		sv.Value = petConfig.Name
		spawnPet(player, petConfig)
		notify(player, petConfig.Name .. " is following you!")
	end
end)
