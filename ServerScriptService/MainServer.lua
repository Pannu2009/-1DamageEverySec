-- DataStore, Passive Damage, Rebirth

local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData")

local Shared_ = require(Rep.Shared.RebirthConfig)
local GuiRemote = Rep.Remotes.EverySec
local RebirthEvent = Rep.Remotes.RebirthEvent


local function GetMuli(revLevel)
	local data = Shared_.Data[revLevel]
	return data and data.Multi or 1
end

local function updateStats(player)
	local Stats = player:WaitForChild("leaderstats")
	local utils = player:WaitForChild("Utils")
	if not Stats or not utils then return end
	
	local wins = Stats:WaitForChild("Wins")
	local damage = utils:WaitForChild("Damage")
	local rebirth = utils:WaitForChild("Rebirth")
	
	if not (wins and damage and rebirth) then return end
	
	local multi = GetMuli(rebirth.Value)
	local finalDamage = damage.Value * multi ------ multi is here add gamepass later
	
	local char = player.Character
	if char then
		local Sword = char:FindFirstChild("Sword")
		if Sword then
			Sword:SetAttribute("Damage",finalDamage)
		end
	end
	
	GuiRemote:FireClient(player, {
		Damage = damage.Value,
		finalDamage
	})
end

local function setupPlayer(player)
	
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
	
	local damage = Instance.new("NumberValue")
	damage.Name = "Damage"
	damage.Value = 1
	damage.Parent = utils
	
	local rebirth = Instance.new("IntValue")
	rebirth.Name = "Rebirth"
	rebirth.Value = 0
	rebirth.Parent = utils
	
	local sucess, data = pcall(function()
		return DataStore:GetAsync("Player_" .. player.UserId)
	end)
	
	if sucess and data then
		damage.Value = data.Damage or 1
		wins.Value = data.Wins or 0
		rebirth.Value = data.Rebirths or 0
	end
	
	task.spawn(function()
		task.wait(1)
		if player.Character then
			local sword = ServerStorage.Sword:Clone()
			sword:SetAttribute("Damage",damage.Value)
			sword.Parent = player.Character
		end
	end)
	
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			damage.Value += 1
			updateStats(player)
		end
	end)
	
	damage.Changed:Connect(function() updateStats(player) end)
	wins.Changed:Connect(function() updateStats(player) end)
	rebirth.Changed:Connect(function() updateStats(player) end)
	
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		local sword = ServerStorage.Sword:Clone()
		sword:SetAttribute("Damage",damage.Value)
		sword.Parent = char
		updateStats(player)
	end)
end

local function SavePlayer(player)
	local stats = player:FindFirstChild("leaderstats")
	local utils = player:FindFirstChild("Utils")
	if not (stats and utils) then return end
	
	local wins = stats:FindFirstChild("Wins")
	local damage = utils:FindFirstChild("Damage")
	local rebirth = utils:FindFirstChild("Rebirth")
	
	if not (wins and damage and rebirth) then return end
	
	pcall(function()
		DataStore:SetAsync("Player_" .. player.UserId, {
			Wins = wins.Value,
			Damage = damage.Value,
			Rebirths = rebirth.Value
		})
	end)
end

RebirthEvent.OnServerEvent:Connect(function(player)
	local Stats = player:FindFirstChild("leaderstats")
	local Utils = player:FindFirstChild("Utils")
	if not (Stats and Utils) then return end
	
	local Wins = Stats:FindFirstChild("Wins")
	local Rebirth = Utils:FindFirstChild("Rebirth")
	local Damage = Utils:FindFirstChild("Damage")
	
	if not (Wins and Rebirth and Damage) then return end
	
	local nextLevel = Rebirth.Value + 1
	local required = Shared_.Data[nextLevel]
	
	if not required then
		RebirthEvent:FireClient(player,false,"Max Rebirth Reached")
		return
	end
	
	if Wins.Value >= required.WinsReq then
		Wins.Value = 0
		Rebirth.Value += 1
		Damage.Value = 1 -- reset damage
		RebirthEvent:FireClient(player,true," rebirthed, You are now x"..GetMuli(Rebirth.Value))
	else
		RebirthEvent:FireClient(player,false,"Not enough wins")
	end
	
end)

Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)
end)
Players.PlayerRemoving:Connect(function(plr)  
	SavePlayer(plr)
end)
