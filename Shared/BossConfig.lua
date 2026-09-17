local BossConfig = {}

BossConfig.WarningAlert      = 60 -- 60 seconds before Starting thats at 24th minute
BossConfig.JoinWindow        = 30 -- 30 seconds before Starting thats 24:30 , Shows players that they can join the event
BossConfig.WarmUpTime        = 15 -- 15 Seconds before when boss spawns in arena and players can start fighting 24:45
BossConfig.FightDuration     = 300 -- 300 seconds = 5 minutes,, 30th min it must end
BossConfig.CoolDownAfter     = 25 * 60 -- until next event 25 minutes = 1500 seconds
BossConfig.BaseShards        = 100 -- 100 Shards for winning -- Boss reward
BossConfig.MinHitRequired    = 1 -- 1 hit to boss at least for claiming reward



BossConfig.ArenaSetup = { -- Worte 0 as its not made yet
	PlayerTeleport_Area  = 0,
	BossSpawn_Area       = 0,
	ArenaPillars         = {}
}

BossConfig.BossDivision = {
	HpMultiplier           = 120, -- BossHp = playerTotalDamage * 120 cause hard 
	PillarsCount           = 5,   -- 5 Pilar + 2x BossBody = 7 parts 
	PilarHpDivison         = 7,   -- BossHp / 7 = 1 Pilar Hp 
	
}

BossConfig.Traits  = {
	{Name = "Void Prince",        Chance = 75,      ShardBonus = 0,         LootSword = nil},
	{Name = "Void Servent", Chance = 20,      ShardBonus = 0.50,      LootSword = nil,               },
	{Name = "Void King",   Chance = 5,       ShardBonus = 0.65,      LootSword = "Void Blade",     },
	
}

BossConfig.SpecialTable = {
	{Name = "Void Servent",       Chance = 55,      ShardBonus = 0.50,      LootSword = nil,               },
	{Name = "Void   King",       Chance = 45,      ShardBonus = 0.65,      LootSword = "Void Blade",      },
}

function BossConfig.RollTrait(BossCount) 
	local Count = BossCount
	if Count >= 12 then 
		local Table_Special = BossConfig.SpecialTable
		local roll = math.random(1, 100)
		local cumulativeChance = 0
		for _, trait in ipairs(Table_Special) do
			cumulativeChance = cumulativeChance + trait.Chance
			if roll <= cumulativeChance then
				return trait
			end
		end
		return BossConfig.SpecialTable[1] -- fallback
	else
		local Table_Trait = BossConfig.Traits
		local roll = math.random(1, 100)
		local cumulativeChance = 0
		for _, trait in ipairs(Table_Trait) do
			cumulativeChance = cumulativeChance + trait.Chance
			if roll <= cumulativeChance then
				return trait
			end
		end
		return BossConfig.Traits[1] -- fallback
	end
end

BossConfig.Attacks = {
	{Name  = "Slam",          Damage = 25, Radius = 30, CoolDown = 6},  -- Slams his Hand down
	{Name  = "ShockWave",     Damage = 45, Radius = 30, CoolDown = 12}, -- Creates a Shockwave thats player can jump over or get hit by
	{Name  = "VoidThrow",     Damage = 70, Radius = 20, CoolDown = 20}, -- throws Metors of void in whole map leaving only some spot 
	{Name  = "VoidZone",      Damage = 100, Radius = 20, CoolDown = 25}, -- Creates a Zone of void that does damage to player
	
}

return BossConfig
