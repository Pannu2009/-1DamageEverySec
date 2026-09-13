local Tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local WallEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WallEvent")

local canAttack = true
local attackCooldown = 0.5 -- Time between swings

Tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack = false

	local char = player.Character
	if not char then 
		canAttack = true
		return 
	end

	-- Raycast forward to hit wall
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterAncestorsInstances = {char}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local rayResult = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 10, raycastParams)
		
		if rayResult and rayResult.Instance then
			local hitPart = rayResult.Instance
			if hitPart.Name:find("Wall") then
				-- Get damage attribute set by MainServer
				local damageVal = Tool:GetAttribute("Damage") or 1
				WallEvent:FireServer("DamageWall", damageVal)
			end
		end
	end

	task.wait(attackCooldown)
	canAttack = true
end)

