local rep = game:GetService("ReplicatedStorage")
local wallConfig = require(rep:WaitForChild("Shared"):WaitForChild("WallConfig"))
local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

for groupIndex, groupData in ipairs(wallConfig.Groups) do
	local groupName = "Group" .. groupIndex
	-- Use FindFirstChild so missing groups in Workspace don't cause an infinite yield error
	local groupFolder = wallFolder:FindFirstChild(groupName)
	
	if not groupFolder then
		continue
	end
	
	local walls = {}
	for _, child in ipairs(groupFolder:GetChildren()) do
		-- ONLY select actual wall parts, ignore Win parts like WinsGroup1
		if child:IsA("BasePart") and child.Name:find("Wall") then
			table.insert(walls, child)
		end
	end
	
	table.sort(walls, function(a, b)
		local NumA = tonumber(a.Name:match("%d+")) or 0
		local NumB = tonumber(b.Name:match("%d+")) or 0
		return NumA < NumB
	end)
	
	for i, wall in ipairs(walls) do
		local hp = groupData.Healths[i]
		if not hp then continue end
		
		wall:SetAttribute("HP", hp)
		wall:SetAttribute("MaxHp", hp)
		wall:SetAttribute("GroupIndex", groupIndex)
		wall:SetAttribute("WallIndex", i)
		
		wall.Anchored = true
		wall.CanCollide = true
		wall.Transparency = 0
		
		local existing = wall:FindFirstChild("HealthBar")
		if existing then
			existing:Destroy()
		end
		
		local healthBar = Instance.new("BillboardGui")
		healthBar.Name = "HealthBar"
		healthBar.Size = UDim2.new(0, 150, 0, 40)
		healthBar.StudsOffset = Vector3.new(0, 4, 0)
		healthBar.AlwaysOnTop = true
		healthBar.MaxDistance = 100
		healthBar.Enabled = true
		healthBar.Parent = wall
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 0.5
		label.TextColor3 = Color3.new(1, 1, 1)
		label.BackgroundColor3 = Color3.new(0, 0, 0)
		label.Text = "HP: " .. hp .. "/" .. hp
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = healthBar
	end
	print("WallSetup Configured " .. groupName)
end
print("Complete setup")
