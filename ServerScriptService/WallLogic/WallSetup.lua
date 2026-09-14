local rep = game:GetService("ReplicatedStorage")
local wallConfig = require(rep:WaitForChild("Shared"):WaitForChild("WallsConfig"))
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

		-- Remove old server-side health bars. The wall GUI is now created
		-- per-player on the client, so ONLY the player's current wall
		-- shows a health bar (see WallClient).
		local existing = wall:FindFirstChild("HealthBar")
		if existing then
			existing:Destroy()
		end
		local existingGui = wall:FindFirstChild("WallHealthGui")
		if existingGui then
			existingGui:Destroy()
		end
	end
	print("WallSetup Configured " .. groupName)
end
print("Complete setup")
