local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Map = workspace:WaitForChild("Map"):WaitForChild("walls")

local WallEvent = ReplicatedStorage.Remotes:WaitForChild("WallEvent")

local player = Players.LocalPlayer


local brokenWalls = {} 

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

local function overflowText(overflow)
	overflow = tonumber(overflow) or 0
	if overflow <= 0 then return "" end
	if overflow >= 1000000 then
		return string.format("  (+%.1fM stored)", overflow / 1000000)
	elseif overflow >= 10000 then
		return string.format("  (+%.1fK stored)", overflow / 1000)
	end
	return "  (" .. math.floor(overflow) .. " stored)"
end

local function showWallGui(groupIndex, wallIndex, hp, maxHp, overflow)
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
	label.Text = "Wall " .. wallIndex .. ": " .. hp .. " / " .. maxHp .. overflowText(overflow)
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

local function updateWallGui(hp, maxHp, overflow)
	if not currentGui then return end
	maxHp = math.max(tonumber(maxHp) or 1, 1)
	local ratio = math.clamp((tonumber(hp) or 0) / maxHp, 0, 1)
	local bar = currentGui:FindFirstChild("Bar")
	local fill = bar and bar:FindFirstChild("Fill")
	local label = currentGui:FindFirstChild("Label")
	if fill then
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 80)
	end
	if label then
		label.Text = "Wall " .. currentWall .. ": " .. hp .. " / " .. maxHp .. overflowText(overflow)
	end
end


local function showZoneAnnouncement(zoneName, groupIndex, total)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local old = playerGui:FindFirstChild("ZoneAnnouncement")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ZoneAnnouncement"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 420, 0, 44)
	label.Position = UDim2.new(0.5, -210, 0, 60)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "Zone " .. tostring(groupIndex) .. "/" .. tostring(total) .. "  —  " .. tostring(zoneName or "Unknown")
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	task.delay(2.5, function()
		for _ = 1, 10 do
			label.BackgroundTransparency += 0.075
			label.TextTransparency += 0.1
			task.wait(0.05)
		end
		gui:Destroy()
	end)
end


WallEvent.OnClientEvent:Connect(function(action, data)
	if action == "ResetProgress" then
		resetAllWalls()
		removeWallGui()
		return
	end
	if typeof(data) ~= "table" then return end

	if action == "Progress" then
		showZoneAnnouncement(data.Zone, data.GroupIndex, data.Total)

	elseif action == "BreakWall" then
		setWallState(data.GroupIndex, data.WallIndex, false, 0.75)
		brokenWalls[data.GroupIndex .. "_" .. data.WallIndex] = true
		removeWallGui() 

	elseif action == "NewWall" then
		showWallGui(data.GroupIndex, data.WallIndex, data.HP, data.MaxHP, data.Overflow)

	elseif action == "Damage" then
		if currentGui and currentGroup == data.GroupIndex and currentWall == data.WallIndex then
			updateWallGui(data.HP, data.MaxHP, data.Overflow)
		else
			showWallGui(data.GroupIndex, data.WallIndex, data.HP, data.MaxHP, data.Overflow)
		end
	end
end)

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

-- Teleport back to current zone button
local playerGui = player:WaitForChild("PlayerGui")

local teleportGui = Instance.new("ScreenGui")
teleportGui.Name = "ZoneTeleportGui"
teleportGui.ResetOnSpawn = false
teleportGui.Parent = playerGui

local teleportButton = Instance.new("TextButton")
teleportButton.Name = "TeleportButton"
teleportButton.Size = UDim2.new(0, 160, 0, 44)
teleportButton.Position = UDim2.new(0, 12, 1, -56)
teleportButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
teleportButton.TextColor3 = Color3.new(1, 1, 1)
teleportButton.Font = Enum.Font.GothamBold
teleportButton.TextScaled = true
teleportButton.Text = "Teleport to Zone"
teleportButton.Parent = teleportGui

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 10)
teleportCorner.Parent = teleportButton

local canTeleport = true
teleportButton.Activated:Connect(function()
	if not canTeleport then return end
	canTeleport = false
	teleportButton.Text = "Teleporting..."
	WallEvent:FireServer("TeleportToZone")
	task.delay(5, function()
		canTeleport = true
		teleportButton.Text = "Teleport to Zone"
	end)
end)