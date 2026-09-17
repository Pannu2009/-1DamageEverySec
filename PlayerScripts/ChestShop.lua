

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage.Remotes
local ShopEvent = Remotes.ShopEvent

local roundTable = workspace:WaitForChild("Map"):WaitForChild("RoundTable")
local Table = roundTable.Interupt -- chest shop opener
local Chests = roundTable.Chests

local Gui = Player:WaitForChild("PlayerGui"):WaitForChild("FrontFaceGui")
local frame = Gui:WaitForChild("GuiStore"):WaitForChild("ChestShopPanel")
local OpenBtn = frame:WaitForChild("OpenBtn")
local nextBtn = frame:WaitForChild("Next")
local costLabel = frame:WaitForChild("Cost")
local Back = frame:WaitForChild("Back")

local ShopConfig = require(ReplicatedStorage.Shared:WaitForChild("ShopConfig"))
local Config = ShopConfig.Chests

local ChestModule = {}

local inShop = false
local selectChest = 1
local chestModels = {}
local touchDebounce = false

-- ===== Highlight helpers =====

function ChestModule.RemoveHilight(Chest)
	for _, d in ipairs(Chest:GetDescendants()) do
		if d:IsA("Highlight") then
			d.Parent = nil
		end
	end
end

function ChestModule.AddHilight(Chest)
	local blackHilight = Color3.fromRGB(0, 0, 0)
	local WhiteColor = Color3.fromRGB(255, 255, 255)

	for _, v in ipairs(Chest:GetChildren()) do
		if v.Name == "UIO" then
			local Hilight = Instance.new("Highlight")
			Hilight.Parent = v
			Hilight.FillColor = WhiteColor
			Hilight.FillTransparency = 1
			Hilight.DepthMode = Enum.HighlightDepthMode.Occluded
			Hilight.OutlineColor = WhiteColor
		end
	end
	local hoops1 = Chest:FindFirstChild("Hoops1")
	for _, v in ipairs(hoops1 and hoops1:GetChildren() or {}) do
		local Hilight = Instance.new("Highlight")
		Hilight.Parent = v
		Hilight.FillColor = blackHilight
		Hilight.FillTransparency = 1
		Hilight.DepthMode = Enum.HighlightDepthMode.Occluded
		Hilight.OutlineColor = blackHilight
	end
	local hoops3 = Chest:FindFirstChild("Hoops3")
	for _, v in ipairs(hoops3 and hoops3:GetChildren() or {}) do
		if v.Name == "IG" then
			continue
		end
		if v.Name == "IF" then
			local Hilight = Instance.new("Highlight")
			Hilight.Parent = v
			Hilight.FillColor = WhiteColor
			Hilight.FillTransparency = 1
			Hilight.DepthMode = Enum.HighlightDepthMode.Occluded
			Hilight.OutlineColor = WhiteColor
		end
	end
	local keyHole = Chest:FindFirstChild("KeyHole")
	for _, v in ipairs(keyHole and keyHole:GetChildren() or {}) do
		local Hilight = Instance.new("Highlight")
		Hilight.Parent = v
		Hilight.FillColor = WhiteColor
		Hilight.FillTransparency = 1
		Hilight.DepthMode = Enum.HighlightDepthMode.Occluded
		Hilight.OutlineColor = WhiteColor
	end
	return true
end

-- Highlight only the currently selected chest
local function updateHilight()
	for _, model in ipairs(chestModels) do
		ChestModule.RemoveHilight(model)
	end
	local model = chestModels[selectChest]
	if model then
		ChestModule.AddHilight(model)
	end
end

-- ===== GUI =====

local function fmt(n)
	n = tonumber(n) or 0
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n))
end

local function updatePanel()
	local chest = Config[selectChest]
	if chest then
		costLabel.Text = chest.Name .. "\n" .. fmt(chest.Cost) .. " Wins"
	end
	updateHilight()
end

local function showMessage(text, color)
	costLabel.Text = text
	costLabel.TextColor3 = color or Color3.fromRGB(255, 220, 100)
	task.delay(3, function()
		if costLabel.Parent then
			costLabel.TextColor3 = Color3.new(1, 1, 1)
			updatePanel()
		end
	end)
end

local function openShop()
	if inShop then return end
	inShop = true
	frame.Visible = true
	updatePanel()
end

function ChestModule.CloseShop()
	inShop = false
	frame.Visible = false
	for _, model in ipairs(chestModels) do
		ChestModule.RemoveHilight(model)
	end
end

-- ===== Init =====

function ChestModule.Init()
	-- map chest models to config order (Green, Red, Pink -> Wooden, Golden, Cosmic)
	chestModels = Chests:GetChildren()

	frame.Visible = false

	-- close button (panel doesn't have one built in)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -46, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextScaled = true
	closeBtn.Text = "X"
	closeBtn.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(ChestModule.CloseShop)

	-- navigation
	Back.MouseButton1Click:Connect(function()
		selectChest -= 1
		if selectChest < 1 then selectChest = #Config end
		updatePanel()
	end)

	nextBtn.MouseButton1Click:Connect(function()
		selectChest += 1
		if selectChest > #Config then selectChest = 1 end
		updatePanel()
	end)

	-- open the selected chest (server rolls the reward)
	OpenBtn.MouseButton1Click:Connect(function()
		local chest = Config[selectChest]
		if chest then
			ShopEvent:FireServer("OpenChest", {Name = chest.Name})
		end
	end)

	-- touch the round table to open the shop
	Table.Touched:Connect(function(hit)
		if touchDebounce then return end
		local character = hit:FindFirstAncestorOfClass("Model")
		if character == Player.Character then
			touchDebounce = true
			openShop()
			task.delay(1, function()
				touchDebounce = false
			end)
		end
	end)

	-- auto-close when the player walks away from the table
	task.spawn(function()
		while true do
			task.wait(0.5)
			if inShop then
				local char = Player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if not hrp or (hrp.Position - roundTable.Position).Magnitude > 40 then
					ChestModule.CloseShop()
				end
			end
		end
	end)

	-- results / errors from the server
	ShopEvent.OnClientEvent:Connect(function(action, payload)
		if action == "ChestResult" and typeof(payload) == "table" then
			local text
			if payload.Type == "Shards" then
				text = "+" .. fmt(payload.Amount) .. " Shards!"
			elseif payload.Type == "Cosmetic" then
				text = "You got the " .. payload.Name .. " cosmetic!"
			elseif payload.Type == "Pet" then
				text = "You got the " .. payload.Name .. " pet!"
			end
			if text then
				showMessage(text)
			end
		elseif action == "Error" and inShop then
			showMessage(tostring(payload), Color3.fromRGB(255, 120, 120))
		end
	end)
end

-- to do list
-- every chest have camera -- Might need to adjust angle a bit
-- make round table rotate for each player (client-side only)
-- chest open animation + show item, close back after 5 sec
-- vfx on chests

return ChestModule
