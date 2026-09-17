
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")

local ShopConfig = require(Rep.Shared:WaitForChild("ShopConfig"))
local ShopEvent = Rep.Remotes:WaitForChild("ShopEvent")

local player = Players.LocalPlayer

local module = {}

local function fmt(n)
	n = tonumber(n) or 0
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n))
end

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
end

local function makeLabel(parent, text, size, pos)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.TextScaled = true
	l.Text = text
	l.Parent = parent
	return l
end

local function makeButton(parent, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color or Color3.fromRGB(60, 120, 200)
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextScaled = true
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	makeCorner(b)
	return b
end

function module.Init()
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end
	local gui = playerGui:WaitForChild("FrontFaceGui", 10)
	if not gui then return end
	local frame = gui:WaitForChild("Frame", 10)
	if not frame then return end

	local openButton = frame.ShopFrames:FindFirstChild("WinsShopGui")
	local guiStore = gui:FindFirstChild("GuiStore")
	if not (openButton and guiStore) then return end

	-- ===== Panel shell =====
	local panel = Instance.new("Frame")
	panel.Name = "WinsShopPanel"
	panel.Size = UDim2.new(0, 460, 0, 460)
	panel.Position = UDim2.new(0.5, -230, 0.5, -230)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	panel.Visible = false
	panel.Parent = guiStore
	makeCorner(panel, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 160, 255)
	stroke.Thickness = 2
	stroke.Parent = panel

	makeLabel(panel, "WINS SHOP", UDim2.new(1, -60, 0, 34), UDim2.new(0, 16, 0, 8))

	local closeBtn = makeButton(panel, "X", UDim2.new(0, 34, 0, 34), UDim2.new(1, -46, 0, 8), Color3.fromRGB(180, 60, 60))

	local currencyLabel = makeLabel(panel, "Wins: 0 | Shards: 0", UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 0, 44))
	currencyLabel.TextColor3 = Color3.fromRGB(255, 220, 100)

	local msgLabel = makeLabel(panel, "", UDim2.new(1, -32, 0, 20), UDim2.new(0, 16, 0, 68))
	msgLabel.TextColor3 = Color3.fromRGB(255, 120, 120)

	-- ===== Convert section =====
	makeLabel(panel, "CONVERT WINS TO SHARDS (1 Win = " .. ShopConfig.ConvertRate .. " Shards)", UDim2.new(1, -32, 0, 20), UDim2.new(0, 16, 0, 94))

	local amountBox = Instance.new("TextBox")
	amountBox.Size = UDim2.new(0, 120, 0, 32)
	amountBox.Position = UDim2.new(0, 16, 0, 118)
	amountBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	amountBox.Font = Enum.Font.GothamBold
	amountBox.TextColor3 = Color3.new(1, 1, 1)
	amountBox.PlaceholderText = "Amount"
	amountBox.Text = ""
	amountBox.Parent = panel
	makeCorner(amountBox)

	local convertBtn = makeButton(panel, "Convert", UDim2.new(0, 100, 0, 32), UDim2.new(0, 146, 0, 118), Color3.fromRGB(60, 160, 90))
	local convertAllBtn = makeButton(panel, "Convert All", UDim2.new(0, 120, 0, 32), UDim2.new(0, 254, 0, 118), Color3.fromRGB(60, 160, 90))

	-- ===== Cosmetics list =====
	-- (chests moved to the 3D round table ChestShop)
	makeLabel(panel, "SWORD COSMETICS", UDim2.new(0, 210, 0, 20), UDim2.new(0, 16, 0, 158))

	local cosmeticList = Instance.new("ScrollingFrame")
	cosmeticList.Size = UDim2.new(0, 210, 0, 190)
	cosmeticList.Position = UDim2.new(0, 16, 0, 182)
	cosmeticList.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	cosmeticList.ScrollBarThickness = 6
	cosmeticList.CanvasSize = UDim2.new(0, 0, 0, 0)
	cosmeticList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	cosmeticList.Parent = panel
	makeCorner(cosmeticList)

	local cosmeticLayout = Instance.new("UIListLayout")
	cosmeticLayout.Padding = UDim.new(0, 4)
	cosmeticLayout.Parent = cosmeticList

	local cosmeticPad = Instance.new("UIPadding")
	cosmeticPad.PaddingTop = UDim.new(0, 4)
	cosmeticPad.PaddingLeft = UDim.new(0, 4)
	cosmeticPad.PaddingRight = UDim.new(0, 4)
	cosmeticPad.Parent = cosmeticList

	-- ===== Pets list =====
	makeLabel(panel, "PET COMPANIONS (auto-attack)", UDim2.new(0, 210, 0, 20), UDim2.new(0, 236, 0, 158))

	local petList = Instance.new("ScrollingFrame")
	petList.Size = UDim2.new(0, 210, 0, 190)
	petList.Position = UDim2.new(0, 236, 0, 182)
	petList.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	petList.ScrollBarThickness = 6
	petList.CanvasSize = UDim2.new(0, 0, 0, 0)
	petList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petList.Parent = panel
	makeCorner(petList)

	local petLayout = Instance.new("UIListLayout")
	petLayout.Padding = UDim.new(0, 4)
	petLayout.Parent = petList

	local petPad = Instance.new("UIPadding")
	petPad.PaddingTop = UDim.new(0, 4)
	petPad.PaddingLeft = UDim.new(0, 4)
	petPad.PaddingRight = UDim.new(0, 4)
	petPad.Parent = petList

	-- ===== Entry builders =====

	local function buildEntry(list, config, listName, kind)
		local entry = Instance.new("TextButton")
		entry.Size = UDim2.new(1, 0, 0, 34)
		entry.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
		entry.Font = Enum.Font.GothamBold
		entry.TextColor3 = Color3.new(1, 1, 1)
		entry.TextScaled = true
		entry.Parent = list
		makeCorner(entry)

		local owned = false
		local equipped = false

		local function refresh(state)
			owned = state.owned
			equipped = state.equipped
			if equipped then
				entry.Text = config.Name .. " [EQUIPPED]"
				entry.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
			elseif owned then
				entry.Text = config.Name .. " [EQUIP]"
				entry.BackgroundColor3 = Color3.fromRGB(55, 90, 150)
			else
				entry.Text = config.Name .. " - " .. fmt(config.Cost) .. " Wins"
				entry.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
			end
		end

		entry.MouseButton1Click:Connect(function()
			if equipped then
				ShopEvent:FireServer(kind == "pet" and "EquipPet" or "EquipCosmetic", {Name = ""})
			elseif owned then
				ShopEvent:FireServer(kind == "pet" and "EquipPet" or "EquipCosmetic", {Name = config.Name})
			else
				ShopEvent:FireServer(kind == "pet" and "BuyPet" or "BuyCosmetic", {Name = config.Name})
			end
		end)

		return {Button = entry, Refresh = refresh, Config = config}
	end

	local cosmeticEntries = {}
	for _, config in ipairs(ShopConfig.Cosmetics) do
		cosmeticEntries[config.Name] = buildEntry(cosmeticList, config, "Cosmetics", "cosmetic")
	end

	local petEntries = {}
	for _, config in ipairs(ShopConfig.Pets) do
		petEntries[config.Name] = buildEntry(petList, config, "Pets", "pet")
	end

	-- ===== State sync =====

	local function refreshAll(state)
		if state.Wins ~= nil then
			currencyLabel.Text = "Wins: " .. fmt(state.Wins) .. " | Shards: " .. fmt(state.Shards or 0)
		end
		local ownedC = state.Cosmetics or {}
		local ownedP = state.Pets or {}
		for name, entry in pairs(cosmeticEntries) do
			entry.Refresh({
				owned = table.find(ownedC, name) ~= nil,
				equipped = state.EquippedCosmetic == name,
			})
		end
		for name, entry in pairs(petEntries) do
			entry.Refresh({
				owned = table.find(ownedP, name) ~= nil,
				equipped = state.EquippedPet == name,
			})
		end
	end

	-- ===== Actions =====

	openButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	convertBtn.MouseButton1Click:Connect(function()
		local amount = tonumber(amountBox.Text)
		if amount then
			ShopEvent:FireServer("Convert", {Amount = math.floor(amount)})
		end
	end)

	convertAllBtn.MouseButton1Click:Connect(function()
		ShopEvent:FireServer("Convert", {All = true})
	end)

	-- ===== Server events =====

	ShopEvent.OnClientEvent:Connect(function(action, payload)
		if action == "Update" and typeof(payload) == "table" then
			refreshAll(payload)
			if payload.Message then
				msgLabel.Text = payload.Message
				msgLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
				task.delay(2.5, function()
					if msgLabel.Parent then msgLabel.Text = "" end
				end)
			end
		elseif action == "Error" then
			msgLabel.Text = tostring(payload)
			msgLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
			task.delay(2.5, function()
				if msgLabel.Parent then msgLabel.Text = "" end
			end)
		end
	end)

	-- Initial state request
	ShopEvent:FireServer("Refresh", {})
end

return module
