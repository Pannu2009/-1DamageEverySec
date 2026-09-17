local wallConfig = {}

local START_HP = 5
local GROUP_GROWTH = 2.6
local MIN_WALLS = 5

wallConfig.INFINITY_HP_MULTIPLIER = 5
wallConfig.INFINITY_REWARD_MULTIPLIER = 2

local function getWallMulti(groupIndex)
	if groupIndex <= 2 then
		return 1.5
	elseif groupIndex <= 5 then
		return 1.95
	elseif groupIndex <= 10 then
		return 2.20
	elseif groupIndex <= 20 then
		return 2.60
	else
		return 3.00 -- Default for groups 21+ (Infinity Zone)
	end
end

local function getWallCount(groupIndex)
	if groupIndex <= 5 then
		return 5
	elseif groupIndex <= 10 then
		return 6
	elseif groupIndex <= 15 then
		return 7
	elseif groupIndex <= 20 then
		return 8
	elseif groupIndex <= 25 then
		return 9
	elseif groupIndex <= 30 then
		return 10
	elseif groupIndex <= 34 then
		return 11
	else
		return 15 -- Infinity Zone never Ending Zone
	end
end

local ZoneTypes = {
	{"Wood_Zone", Enum.Material.WoodPlanks, Color3.fromRGB(120, 80, 40)},
	{"Stone_Zone", Enum.Material.Slate, Color3.fromRGB(130, 130, 130)},
	{"Copper_Zone", Enum.Material.Metal, Color3.fromRGB(184, 115, 51)},
	{"Bronze_Zone", Enum.Material.Metal, Color3.fromRGB(205, 127, 50)},
	{"Iron_Zone", Enum.Material.Metal, Color3.fromRGB(110, 110, 120)},
	{"Steel_Zone", Enum.Material.DiamondPlate, Color3.fromRGB(160, 170, 180)},
	{"Zinc_Zone", Enum.Material.Metal, Color3.fromRGB(180, 190, 200)},
	{"Silver_Zone", Enum.Material.Metal, Color3.fromRGB(192, 192, 192)},
	{"Gold_Zone", Enum.Material.Metal, Color3.fromRGB(255, 200, 50)},
	{"Platinum_Zone", Enum.Material.Metal, Color3.fromRGB(225, 228, 225)},
	{"Titanium_Zone", Enum.Material.Metal, Color3.fromRGB(120, 130, 140)},
	{"Obsidian_Zone", Enum.Material.Basalt, Color3.fromRGB(35, 30, 45)},
	{"Crystal_Zone", Enum.Material.Glass, Color3.fromRGB(120, 220, 255)},
	{"Diamond_Zone", Enum.Material.Glass, Color3.fromRGB(90, 180, 255)},
	{"Netherite_Zone", Enum.Material.Basalt, Color3.fromRGB(70, 50, 80)},
	{"Cosmic_Zone", Enum.Material.Neon, Color3.fromRGB(140, 80, 255)},
	{"Nebula_Zone", Enum.Material.Neon, Color3.fromRGB(255, 100, 200)},
	{"Galaxy_Zone", Enum.Material.Neon, Color3.fromRGB(100, 80, 255)},
	{"Quantum_Zone", Enum.Material.ForceField, Color3.fromRGB(0, 255, 200)},
	{"Plasma_Zone", Enum.Material.Neon, Color3.fromRGB(255, 120, 50)},
	{"Eclipse_Zone", Enum.Material.Basalt, Color3.fromRGB(60, 40, 30)},
	{"Meteor_Zone", Enum.Material.Rock, Color3.fromRGB(140, 90, 60)},
	{"Void_Zone", Enum.Material.Neon, Color3.fromRGB(60, 40, 90)},
	{"Aurora_Zone", Enum.Material.Neon, Color3.fromRGB(100, 255, 180)},
	{"Hell_Zone", Enum.Material.CrackedLava, Color3.fromRGB(200, 50, 30)},
	{"Celestial_Zone", Enum.Material.Neon, Color3.fromRGB(255, 240, 180)},
	{"Ethereal_Zone", Enum.Material.ForceField, Color3.fromRGB(255, 200, 230)},
	{"Transcendent_Zone", Enum.Material.Neon, Color3.fromRGB(255, 220, 120)},
	{"Divine_Zone", Enum.Material.Neon, Color3.fromRGB(255, 255, 180)},
	{"Omega_Zone", Enum.Material.ForceField, Color3.fromRGB(255, 100, 60)},
	{"Astral_Zone", Enum.Material.Neon, Color3.fromRGB(90, 150, 255)},
	{"Ascendant_Zone", Enum.Material.ForceField, Color3.fromRGB(180, 255, 255)},
	{"Genesis_Zone", Enum.Material.Neon, Color3.fromRGB(120, 255, 120)},
	{"Elemental_Zone", Enum.Material.Neon, Color3.fromRGB(255, 170, 80)},
	{"Infinity_Zone", Enum.Material.ForceField, Color3.fromRGB(240, 240, 255)},
}

wallConfig.Groups = {}

for groupIndex, zoneType in ipairs(ZoneTypes) do
	local healths = {}
	local baseHp = math.floor(START_HP * (groupIndex ^ GROUP_GROWTH))
	local wallMulti = getWallMulti(groupIndex)
	local wallCount = getWallCount(groupIndex)

	for wallIndex = 1, wallCount do
		healths[wallIndex] = math.floor(baseHp * (wallMulti ^ (wallIndex - 1)))
	end

	table.insert(wallConfig.Groups, {
		Name = zoneType[1],
		HP = healths,
		WinReward = 5 * groupIndex,
		WallMultiplier = wallMulti,
		WallCount = wallCount,
		Material = zoneType[2],
		Color = zoneType[3],
		IsInfinity = groupIndex == #ZoneTypes,
	})
end

wallConfig.TotalGroups = #wallConfig.Groups
wallConfig.InfinityGroupIndex = #wallConfig.Groups

function wallConfig.GetMaxHp(groupIndex, wallIndex)
	local group = wallConfig.Groups[groupIndex]
	if not group then
		return 0
	end
	return group.HP[wallIndex] or 0
end

wallConfig.GetMaxHP = wallConfig.GetMaxHp

function wallConfig.GetZoneName(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and group.Name or "Unknown"
end

wallConfig.GetZoneNames = wallConfig.GetZoneName

function wallConfig.GetWinReward(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and group.WinReward or 0
end

function wallConfig.GetWallCount(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and #group.HP or 0
end

function wallConfig.GetMaterial(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and group.Material or Enum.Material.Plastic
end

function wallConfig.GetColor(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and group.Color or Color3.fromRGB(163, 162, 165)
end

function wallConfig.IsInfinityGroup(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and group.IsInfinity or false
end

function wallConfig.GetEffectiveMaxHp(groupIndex, wallIndex, infinityLevel)
	local base = wallConfig.GetMaxHp(groupIndex, wallIndex)
	if base <= 0 then return 0 end
	infinityLevel = math.max(tonumber(infinityLevel) or 1, 1)
	if not wallConfig.IsInfinityGroup(groupIndex) or infinityLevel <= 1 then
		return base
	end
	return math.floor(base * (wallConfig.INFINITY_HP_MULTIPLIER ^ (infinityLevel - 1)))
end

function wallConfig.GetInfinityReward(groupIndex, infinityLevel)
	local base = wallConfig.GetWinReward(groupIndex)
	if not wallConfig.IsInfinityGroup(groupIndex) then
		return base
	end
	infinityLevel = math.max(tonumber(infinityLevel) or 1, 1)
	return base * (wallConfig.INFINITY_REWARD_MULTIPLIER ^ (infinityLevel - 1))
end

return wallConfig
