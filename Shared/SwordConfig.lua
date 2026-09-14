local SwordConfig = {}

-- All sword multipliers live here.
-- The default ServerStorage tool is named "sword".
-- When MainServer gives it to a player, it is tagged as the Rusty Sword.

SwordConfig.DefaultSword = "Rusty Sword"
SwordConfig.DefaultModelName = "sword"
SwordConfig.AttackCooldown = 0.4

SwordConfig.Swords = {
	{Name = "Rusty Sword", Cost = 0,   Multi = 1.0},
	{Name = "Iron Blade",  Cost = 500, Multi = 1.5},
	{Name = "Void Blade",  Cost = 0,   Multi = 7.0, BossDrop = true},
}

function SwordConfig.GetSword(name)
	for _, sword in ipairs(SwordConfig.Swords) do
		if sword.Name == name then
			return sword
		end
	end
	return nil
end

function SwordConfig.GetMulti(name)
	local sword = SwordConfig.GetSword(name)
	return sword and sword.Multi or 1
end

return SwordConfig
