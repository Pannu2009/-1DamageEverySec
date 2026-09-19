
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WallEvent = Remotes:WaitForChild("WallEvent")
local SwordConfig = require(ReplicatedStorage.Shared:WaitForChild("SwordConfig"))

local module = {}
local connected = setmetatable({}, { __mode = "k" })

local function connectTool(tool)
	if not tool:IsA("Tool") or connected[tool] then return end
	connected[tool] = true

	local attacking = false
	local cooldown = SwordConfig.AttackCooldown or 0.4

	tool.Activated:Connect(function()
		if attacking then return end
		if tool.Parent ~= player.Character then return end
		attacking = true

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {char}
			params.FilterType = Enum.RaycastFilterType.Exclude

			local result = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 16, params)
			if result and result.Instance then
				local hitPart = result.Instance
				local groupIndex = hitPart:GetAttribute("GroupIndex")
				local wallIndex = hitPart:GetAttribute("WallIndex")

				if hitPart.Name:match("^Wall%d+$") and groupIndex and wallIndex then
					WallEvent:FireServer("DamageWall", {
						Group = tonumber(groupIndex),
						Wall = tonumber(wallIndex),
					})
				end
			end
		end

		task.delay(cooldown, function()
			attacking = false
		end)
	end)
end

local function scan(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		connectTool(child)
	end
end

function module.Init()
	local backpack = player:WaitForChild("Backpack", 10)
	if backpack then
		backpack.ChildAdded:Connect(connectTool)
		scan(backpack)
	end

	local function characterAdded(character)
		character.ChildAdded:Connect(connectTool)
		scan(character)
	end

	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		characterAdded(player.Character)
	end
end

return module
