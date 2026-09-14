local wallConfig = {}

-- Current wall formula.
local START_HP = 5
local GROUP_GROWTH = 2.2
local WALLS_PER_GROUP = 5

local function getWallMulti(groupIndex)
	if groupIndex <= 2 then
		return 1.8
	elseif groupIndex <= 5 then
		return 2.4
	elseif groupIndex <= 10 then
		return 2.9
	else
		return 3.1
	end
end

local ZoneNames = {
	"Wood_Zone", "Stone_Zone", "Iron_Zone", "Metal_Zone", "Zinc_Zone", "Copper_Zone", "Bronze_Zone",
	"Silver_Zone", "Gold_Zone", "Platinum_Zone", "Obsidian_Zone", "Crystal_Zone", "Emerald_Zone",
	"Diamond_Zone", "Titanium_Zone", "Sky_Zone", "Meteor_Zone", "Void_Zone", "Cosmic_Zone", "Hell_Zone",
	"Heaven_Zone", "LiverPool_Zone"
}

wallConfig.Groups = {}

for groupIndex = 1, 20 do
	local healths = {}
	local baseHp = math.floor(START_HP * (groupIndex ^ GROUP_GROWTH))
	local wallMulti = getWallMulti(groupIndex)

	for wallIndex = 1, WALLS_PER_GROUP do
		healths[wallIndex] = math.floor(baseHp * (wallMulti ^ (wallIndex - 1)))
	end

	table.insert(wallConfig.Groups, {
		Name = ZoneNames[groupIndex] or ("Zone_" .. groupIndex),
		HP = healths,
		WinReward = 5 * groupIndex,
		WallMultiplier = wallMulti,
	})
end

function wallConfig.GetMaxHp(groupIndex, wallIndex)
	local group = wallConfig.Groups[groupIndex]
	if not group then
		return 0
	end
	return group.HP[wallIndex] or 0
end

-- Keep both spellings available so older code cannot break.
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

return wallConfig
