local rep = game:GetService("ReplicatedStorage")
local wallConfig = require(rep:WaitForChild("Shared"):WaitForChild("WallsConfig"))
local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

for groupIndex, groupData in ipairs(wallConfig.Groups) do
	local groupName = "Group" .. groupIndex
	local groupFolder = wallFolder:WaitForChild(groupName)
	
	if not groupFolder then
		warn("Group folder not found: " .. groupName)
		continue
	end
	
	local walls = groupFolder:GetChildren()
	table.sort(walls,function(a,b)
		local NumA = tonumber(a.Name:match("%d+")) or 0
		local NumB = tonumber(b.Name:match("%d+")) or 0
		return NumA < NumB
	end)
	
	for i, wall in ipairs(walls) do
		if not wall:IsA("BasePart") then continue end
		
		local hp = groupData.walls[i]
		wall:SetAttribute("HP",hp)
		wall:SetAttribute("MaxHp",hp)
		wall:SetAttribute("GroupIndex",groupIndex)
		wall:SetAttribute("WallIndex",i)
		
		wall.Anchored = true
		wall.CanCollide = false
		wall.Transparency = 1
		
		local existing = wall:FindFirstChild("HealthBar")
		if existing then
			existing:Destroy()
		end
		
		local healthBar = Instance.new("BillboardGui")
		healthBar.Name = "HealthBar"
		healthBar.Size = UDim2.new(0, 200, 0, 50)
		healthBar.StudsOffset = Vector3.new(0, 5, 0)
		healthBar.AlwaysOnTop = true
		healthBar.Parent = wall
		healthBar.Enabled = false
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 0.5
		label.TextColor3 = Color3.new(1, 0, 0)
		label.BackgroundColor3 = Color3.new(0, 0, 0)
		label.Text = "HP: " .. hp .. "/" .. hp
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = healthBar
		
	end
	print("WallSetup Congired "..groupName)
end
print("Complete setup")
