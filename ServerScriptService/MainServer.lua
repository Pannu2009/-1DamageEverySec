-- Replace your setupPlayer function with this cleaned-up version:
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
	
	damage.Changed:Connect(function() updateStats(player) end)
	wins.Changed:Connect(function() updateStats(player) end)
	rebirth.Changed:Connect(function() updateStats(player) end)
	
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		if ServerStorage:FindFirstChild("Sword") then
			local sword = ServerStorage.Sword:Clone()
			sword:SetAttribute("Damage", damage.Value)
			sword.Parent = player.Backpack -- Put into Backpack instead of Character directly
		end
		updateStats(player)
	end)
end

