-- FrontFaceGui wiring module
-- Crowns.WinsLabel = wins | Damage.DamageLabel = current damage
-- ShopFrames.RebirthGui = toggle panel | RebirthPanel = rebirth UI

local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")

local RebirthConfig = require(Rep.Shared.RebirthConfig)
local EverySec = Rep.Remotes.EverySec
local RebirthEvent = Rep.Remotes.RebirthEvent
local SwordConfig = require(Rep.Shared.SwordConfig)

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

local function getMulti(level)
	local data = RebirthConfig.Data[level]
	return data and data.Multi or 1
end

function module.Init()
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end
	local gui = playerGui:WaitForChild("FrontFaceGui", 10)
	if not gui then return end

	local frame = gui:WaitForChild("Frame", 10)
	if not frame then return end

	local crowns = frame:FindFirstChild("Crowns")
	local damageFrame = frame:FindFirstChild("Damage")
	local shopFrames = frame:FindFirstChild("ShopFrames")
	local winsLabel = crowns and crowns:FindFirstChild("WinsLabel")
	local damageLabel = damageFrame and damageFrame:FindFirstChild("DamageLabel")
	local openButton = shopFrames and shopFrames:FindFirstChild("RebirthGui")

	local guiStore = gui:FindFirstChild("GuiStore")
	local panel = guiStore and guiStore:FindFirstChild("RebirthPanel")

	-- player stat values
	local leaderstats = player:WaitForChild("leaderstats", 10)
	local utils = player:WaitForChild("Utils", 10)
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	local damage = utils and utils:FindFirstChild("Damage")
	local rebirth = utils and utils:FindFirstChild("Rebirth")

	-- Wins label
	if winsLabel and wins then
		local function updateWins()
			winsLabel.Text = fmt(wins.Value)
		end
		updateWins()
		wins.Changed:Connect(updateWins)
	end

	-- Damage label (shows final damage = base * rebirth multiplier)
	if damageLabel then
		if damage then
			damageLabel.Text = fmt(damage.Value * getMulti(rebirth and rebirth.Value or 0) * SwordConfig.GetMulti(SwordConfig.DefaultSword))
		end
		EverySec.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.FinalDamage then
				damageLabel.Text = fmt(payload.FinalDamage)
			end
		end)
	end

	-- Rebirth panel
	if panel then
		panel.Visible = false

		local left = panel:FindFirstChild("Left")
		local right = panel:FindFirstChild("Right")
		local reqLabel = left and left:FindFirstChild("Requirement")
		local currentLabel = right and right:FindFirstChild("Current")
		local nextLabel = right and right:FindFirstChild("Next")
		local rebirthBtn = panel:FindFirstChild("RebirthButton")

		local function updatePanel()
			local level = rebirth and rebirth.Value or 0
			local nextData = RebirthConfig.Data[level + 1]

			if reqLabel then
				reqLabel.Text = nextData and (fmt(nextData.WinsReq) .. " Wins") or "MAX REACHED"
			end
			if currentLabel then
				currentLabel.Text = "x" .. getMulti(level)
			end
			if nextLabel then
				nextLabel.Text = nextData and ("x" .. nextData.Multi) or "MAX"
			end
		end
		updatePanel()
		if rebirth then
			rebirth.Changed:Connect(updatePanel)
		end

		-- open / close the panel
		if openButton then
			openButton.MouseButton1Click:Connect(function()
				panel.Visible = not panel.Visible
			end)
		end

		-- request a rebirth from the server
		if rebirthBtn then
			rebirthBtn.MouseButton1Click:Connect(function()
				RebirthEvent:FireServer()
			end)
		end

		-- server response feedback
		RebirthEvent.OnClientEvent:Connect(function(success, message)
			if rebirthBtn and message then
				local original = rebirthBtn.Text
				rebirthBtn.Text = message
				task.delay(2, function()
					if rebirthBtn and rebirthBtn.Parent then
						rebirthBtn.Text = original
					end
				end)
			end
			if success then
				panel.Visible = false
			end
		end)
	end
end

return module
