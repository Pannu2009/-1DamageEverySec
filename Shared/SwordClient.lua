-- SwordClient
-- Client only detects the wall the player is looking at.
-- The server decides how much damage is actually dealt.

local Tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WallEvent = Remotes:WaitForChild("WallEvent")

local attackCooldown = 0.4
local canAttack = true

Tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack = false

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {char}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(
			hrp.Position,
			hrp.CFrame.LookVector * 10,
			raycastParams
		)

		if result and result.Instance then
			local hitPart = result.Instance
			local groupIndex = hitPart:GetAttribute("GroupIndex")
			local wallIndex = hitPart:GetAttribute("WallIndex")

			if hitPart.Name:find("Wall") and groupIndex and wallIndex then
				-- Send only the identity of the wall.
				-- Server calculates the real damage from the player's sword.
				WallEvent:FireServer("DamageWall", {
					Group = groupIndex,
					Wall = wallIndex,
				})
			end
		end
	end

	task.wait(attackCooldown)
	canAttack = true
end)
