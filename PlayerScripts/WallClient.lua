local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Map = workspace:WaitForChild("Map"):WaitForChild("walls")

local WallEvent = ReplicatedStorage.Remotes:WaitForChild("WallEvent")

local player = Players.LocalPlayer

-- ===== Wall open/close (local to this player only) =====

local brokenWalls = {} -- tracks which walls this player has broken

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

local function resetAllWalls()
	brokenWalls = {}
	for _, group in ipairs(Map:GetChildren()) do
		for _, wall in ipairs(group:GetChildren()) do
			if wall:IsA("BasePart") and wall.Name:find("Wall") and not wall.Name:find("Wins") then
				wall.CanCollide = true
				wall.Transparency = 0
			end
		end
	end
end

-- ===== Current wall GUI: only ONE wall (the current one) shows a health bar =====

local currentGui = nil
local currentGroup = nil
local currentWall = nil

local function getWall(groupIndex, wallIndex)
	local groupFolder = Map:FindFirstChild("Group" .. groupIndex)
	return groupFolder and groupFolder:FindFirstChild("Wall" .. wallIndex)
end

local function removeWallGui()
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end
	currentGroup = nil
	currentWall = nil
end

local function showWallGui(groupIndex, wallIndex, hp, maxHp)
	removeWallGui()
	local wall = getWall(groupIndex, wallIndex)
	if not wall then return end
	maxHp = math.max(tonumber(maxHp) or 1, 1)
	hp = math.max(tonumber(hp) or 0, 0)

	local bb = Instance.new("BillboardGui")
	bb.Name = "WallHealthGui"
	bb.Size = UDim2.new(0, 170, 0, 52)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 250
	bb.Adornee = wall
	bb.Parent = wall

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = "Wall " .. wallIndex .. ": " .. hp .. " / " .. maxHp
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bb

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 14)
	bar.Position = UDim2.new(0, 0, 0, 28)
	bar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	bar.BorderSizePixel = 0
	bar.Parent = bb

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(60, 255, 120)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	currentGui = bb
	currentGroup = groupIndex
	currentWall = wallIndex
end

local function updateWallGui(hp, maxHp)
	if not currentGui then return end
	maxHp = math.max(tonumber(maxHp) or 1, 1)
	local ratio = math.clamp((tonumber(hp) or 0) / maxHp, 0, 1)
	local bar = currentGui:FindFirstChild("Bar")
	local fill = bar and bar:FindFirstChild("Fill")
	local label = currentGui:FindFirstChild("Label")
	if fill then
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		-- green when healthy, red when low
		fill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 80)
	end
	if label then
		label.Text = "Wall " .. currentWall .. ": " .. hp .. " / " .. maxHp
	end
end

-- ===== Server messages =====

WallEvent.OnClientEvent:Connect(function(action, data)
	if action == "ResetProgress" then
		resetAllWalls()
		removeWallGui()
		return
	end
	if typeof(data) ~= "table" then return end

	if action == "BreakWall" then
		-- Open the broken wall locally for this player
		setWallState(data.GroupIndex, data.WallIndex, false, 0.75)
		brokenWalls[data.GroupIndex .. "_" .. data.WallIndex] = true
		removeWallGui() -- server follows up with NewWall for the next wall

	elseif action == "NewWall" then
		-- Move the health bar GUI onto the new current wall
		showWallGui(data.GroupIndex, data.WallIndex, data.HP, data.MaxHP)

	elseif action == "Damage" then
		-- Update the health bar as the wall takes damage
		if currentGui and currentGroup == data.GroupIndex and currentWall == data.WallIndex then
			updateWallGui(data.HP, data.MaxHP)
		else
			showWallGui(data.GroupIndex, data.WallIndex, data.HP, data.MaxHP)
		end
	end
end)

-- Safety net: if the player respawns, re-apply the walls they already broke
if player then
	player.CharacterAdded:Connect(function()
		for key in pairs(brokenWalls) do
			local g, w = key:match("(%d+)_(%d+)")
			if g and w then
				setWallState(tonumber(g), tonumber(w), false, 0.75)
			end
		end
	end)
end
