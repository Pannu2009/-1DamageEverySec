local PetConfig = {}


-- This Module is not wired yet
-- Also need to PatManager in ServerScriptService,, OrogoNized


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetModels = ReplicatedStorage:WaitForChild("PetModels")
local ProduxtsConfig = require(ReplicatedStorage:WaitForChild("Shared").ProductsConfig)
local PetHilight = ReplicatedStorage:WaitForChild("Asset").PetHilight
local PetLabel = ReplicatedStorage:WaitForChild("Asset").PetLabel


PetConfig.Pets = {
	{Name = "Cube Buddy",   DamagePercent = 0.15, AttackInterval = 2.0, Color = Color3.fromRGB(120, 200, 255), Size = 1.2},
	{Name = "Square Ball",   DamagePercent = 0.25, AttackInterval = 1.75, Color = Color3.fromRGB(200, 80, 80), Size = 1.4},
	{Name = "Dragon",  DamagePercent = 0.40, AttackInterval = 1.5, Color = Color3.fromRGB(90, 220, 120), Size = 1.6},
	{Name = "Void Pet", DamagePercent = 0.60, AttackInterval = 1.0, Color = Color3.fromRGB(40, 20, 80), Size = 1.8},
	{Name = "Exclusive_Orb", DamagePercent = 0.30, AttackInterval = 1.4,   Color = Color3.fromRGB(32, 251, 255), Size = 1.2, StarterPack = true},
}

function PetConfig.GetPetData(name)
	for _, p in ipairs(PetConfig.Pets) do
		if p.Name == name then return p end
	end
	return nil
end

function PetConfig.GetPetModel(name)
	local pet = PetModels:FindFirstChild(name)
	if pet then
		return pet:Clone()
	end
	return nil
end