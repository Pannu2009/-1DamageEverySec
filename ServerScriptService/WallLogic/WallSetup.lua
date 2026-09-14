local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WallConfig = require(ReplicatedStorage.Shared:WaitForChild("WallConfig"))
local wallFolder = workspace:WaitForChild("Map"):WaitForChild("walls")

for groupIndex, groupData in ipairs(WallConfig.Groups) do
	local groupName = "Group" .. groupIndex
	local groupFolder = wallFolder:FindFirstChild(groupName)

	if not groupFolder then
		warn("WallSetup: missing " .. groupName)
		continue
	end

	local walls = {}
	for _, child in ipairs(groupFolder:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^Wall%d+$") then
			table.insert(walls, child)
		end
	end

	table.sort(walls, function(a, b)
		local aNumber = tonumber(a.Name:match("%d+")) or 0
		local bNumber = tonumber(b.Name:match("%d+")) or 0
		return aNumber < bNumber
	end)

	for wallIndex, wall in ipairs(walls) do
		local hp = groupData.HP[wallIndex]
		if not hp then
			warn("WallSetup: no HP for " .. groupName .. "/" .. wall.Name)
			continue
		end

		wall:SetAttribute("HP", hp)
		wall:SetAttribute("MaxHp", hp)
		wall:SetAttribute("GroupIndex", groupIndex)
		wall:SetAttribute("WallIndex", wallIndex)

		wall.Anchored = true
		wall.CanCollide = true
		wall.Transparency = 0

		local existing = wall:FindFirstChild("HealthBar")
		if existing then existing:Destroy() end

		local existingGui = wall:FindFirstChild("WallHealthGui")
		if existingGui then existingGui:Destroy() end
	end

	print("WallSetup configured " .. groupName)
end

print("WallSetup complete")
