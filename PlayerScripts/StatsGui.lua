-- StatsGui: displays Damage, Zone, Wins and a Rebirth button

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local EverySec = ReplicatedStorage.Remotes:WaitForChild("EverySec")
local RebirthEvent = ReplicatedStorage.Remotes:WaitForChild("RebirthEvent")
local WallEvent = ReplicatedStorage.Remotes:WaitForChild("WallEvent")

-- Build the UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatsGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "StatsFrame"
frame.Size = UDim2.new(0, 220, 0, 185)
frame.Position = UDim2.new(0, 10, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local function makeLabel(name, order, height)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -20, 0, height)
	label.Position = UDim2.new(0, 10, 0, order)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	return label
end

local damageLabel = makeLabel("DamageLabel", 8, 25)
damageLabel.Text = "Damage: 1"

local finalDamageLabel = makeLabel("FinalDamageLabel", 35, 25)
finalDamageLabel.Text = "Sword Damage: 1"
finalDamageLabel.TextColor3 = Color3.fromRGB(255, 200, 60)

local zoneLabel = makeLabel("ZoneLabel", 62, 25)
zoneLabel.Text = "Zone: Wood"

local winsLabel = makeLabel("WinsLabel", 89, 25)
winsLabel.Text = "Wins: 0"

local pendingLabel = makeLabel("PendingLabel", 116, 25)
pendingLabel.Text = "Unclaimed Wins: 0"
pendingLabel.TextColor3 = Color3.fromRGB(120, 255, 120)

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.new(1, -20, 0, 30)
rebirthButton.Position = UDim2.new(0, 10, 1, -40)
rebirthButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Text = "Rebirth"
rebirthButton.TextScaled = true
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.BorderSizePixel = 0
rebirthButton.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = rebirthButton

-- Server pushes updated damage every second (and on any stat change)
EverySec.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	if data.Damage then
		damageLabel.Text = "Damage: " .. math.floor(data.Damage)
	end
	if data.FinalDamage then
		finalDamageLabel.Text = "Sword Damage: " .. math.floor(data.FinalDamage)
	end
end)

-- Zone updates from the wall manager
WallEvent.OnClientEvent:Connect(function(action, data)
	if action == "Progress" and typeof(data) == "table" and data.Zone then
		zoneLabel.Text = "Zone: " .. data.Zone
		if data.PendingWins ~= nil then
			pendingLabel.Text = "Unclaimed Wins: " .. data.PendingWins
		end
	end
end)

-- Keep the wins label synced with leaderstats
local function watchLeaderstats()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then return end
	local wins = leaderstats:WaitForChild("Wins", 10)
	if not wins then return end
	winsLabel.Text = "Wins: " .. wins.Value
	wins.Changed:Connect(function(v)
		winsLabel.Text = "Wins: " .. v
	end)
end
task.spawn(watchLeaderstats)

-- Rebirth feedback
local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "Feedback"
feedbackLabel.Size = UDim2.new(0, 300, 0, 30)
feedbackLabel.Position = UDim2.new(0.5, -150, 0, 60)
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
feedbackLabel.TextScaled = true
feedbackLabel.Font = Enum.Font.GothamBold
feedbackLabel.Text = ""
feedbackLabel.Parent = screenGui

RebirthEvent.OnClientEvent:Connect(function(success, message)
	feedbackLabel.Text = message or ""
	feedbackLabel.TextColor3 = success and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 90, 90)
	task.delay(3, function()
		feedbackLabel.Text = ""
	end)
end)

rebirthButton.MouseButton1Click:Connect(function()
	RebirthEvent:FireServer()
end)
