local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Map = workspace:WaitForChild("Map"):WaitForChild("walls")

local WallEvent = ReplicatedStorage.Remotes:WaitForChild("WallEvent")

local function setWallState(groupIndex, wallIndex, canCollide, transparency)
	local groupFolder = Map:FindFirstChild("Group" .. groupIndex)
	if groupFolder then
		local wallPart = groupFolder:FindFirstChild("Wall" .. wallIndex)
		if wallPart then
			wallPart.CanCollide = canCollide
			wallPart.Transparency = transparency
		end
	end
end

-- Server tells client to open a wall locally for them
WallEvent.OnClientEvent:Connect(function(action, data)
	if action == "BreakWall" then
		-- Turn off collision and make invisible only for this player
		setWallState(data.GroupIndex, data.WallIndex, false, 0.75)
		
	elseif action == "ResetProgress" then
		-- Regenerate all walls locally for this player
		for _, group in ipairs(Map:GetChildren()) do
			for _, wall in ipairs(group:GetChildren()) do
				if wall.Name:find("Wall") then
					wall.CanCollide = true
					wall.Transparency = 0
				end
			end
		end
	end
end)

