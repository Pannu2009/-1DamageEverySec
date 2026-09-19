
local ShopConfig = {}


ShopConfig.ConvertRate = 1 -- shards per win
ShopConfig.MinConvert = 10 -- minimum wins per conversion


ShopConfig.Cosmetics = {
	{Name = "Flame Red",    Cost = 250,   Color = Color3.fromRGB(255, 64, 64)},
	{Name = "Toxic Green",  Cost = 500,   Color = Color3.fromRGB(80, 255, 80)},
	{Name = "Electric Blue", Cost = 1000,  Color = Color3.fromRGB(64, 156, 255)},
	{Name = "Royal Purple", Cost = 2000,  Color = Color3.fromRGB(155, 80, 255)},
	{Name = "Golden",       Cost = 5000,  Color = Color3.fromRGB(255, 200, 60)},
	{Name = "Void Black",   Cost = 10000, Color = Color3.fromRGB(25, 25, 30)},
}

function ShopConfig.GetCosmetic(name)
	for _, c in ipairs(ShopConfig.Cosmetics) do
		if c.Name == name then return c end
	end
	return nil
end


ShopConfig.Chests = {
	{
		Name = "Wooden Chest",
		Cost = 50,
		Shards = {100, 500},   -- min/max shard roll
		CosmeticChance = 0.15, -- 15% cosmetic instead of shards
		PetChance = 0,         -- no pets in wooden
	},
	{
		Name = "Golden Chest",
		Cost = 500,
		Shards = {1000, 5000},
		CosmeticChance = 0.30,
		PetChance = 0.05,      -- 5% pet
	},
	{
		Name = "Cosmic Chest",
		Cost = 5000,
		Shards = {10000, 50000},
		CosmeticChance = 0.50,
		PetChance = 0.15,
	},
}

function ShopConfig.GetChest(name)
	for _, c in ipairs(ShopConfig.Chests) do
		if c.Name == name then return c end
	end
	return nil
end


ShopConfig.Pets = {
	{Name = "Cube Buddy",   Cost = 500,   DamagePercent = 0.15, AttackInterval = 2.0, Color = Color3.fromRGB(120, 200, 255), Size = 1.2},
	{Name = "Spike Ball",   Cost = 2500,  DamagePercent = 0.25, AttackInterval = 1.75, Color = Color3.fromRGB(200, 80, 80), Size = 1.4},
	{Name = "Mini Dragon",  Cost = 10000, DamagePercent = 0.40, AttackInterval = 1.5, Color = Color3.fromRGB(90, 220, 120), Size = 1.6},
	{Name = "Void Sentinel", Cost = 50000, DamagePercent = 0.60, AttackInterval = 1.0, Color = Color3.fromRGB(40, 20, 80), Size = 1.8},
}

function ShopConfig.GetPet(name)
	for _, p in ipairs(ShopConfig.Pets) do
		if p.Name == name then return p end
	end
	return nil
end

return ShopConfig