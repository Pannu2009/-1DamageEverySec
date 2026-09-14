local wallConfig = {}

-- NEW FORMUAL TRICK
local START_HP = 5
local GROUP_GROWTH = 2.2
local WALLS_PER_GROUP_Minium = 5

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
	"Wood_Zone", "Stone_Zone", "Iron_Zone", "Metal_Zone","Zinc_Zone","Copper_Zone","Bronze_Zone",
	"Silver_Zone", "Gold_Zone", "platinum_Zone", "Obsidian_Zone", "Crystal_Zone","Emerald_Zone",
	"Diamond_Zone", "titanium_Zone","Sky_Zone","Metor_Zone","Void_Zone","Cosmic_Zone","Hell_Zone",
	"Heaven_Zone", "LiverPool_Zone"
}

wallConfig.Groups = {}

for groupIndex = 1, 20 do
	local healths = {}
	local baseHp = math.floor(START_HP * (groupIndex ^ GROUP_GROWTH))
	local WallMulti = getWallMulti(groupIndex)
	
	for wallIndex = 1, WALLS_PER_GROUP_Minium do
		healths[wallIndex] = math.floor(baseHp * (WallMulti ^ (wallIndex - 1)))
	end
	
	table.insert(wallConfig.Groups, {
		Name = ZoneNames[groupIndex] or ("Zone_"..groupIndex),
		HP = healths,
		WinReward = 5 * groupIndex,
		WallMultiplier = WallMulti
	})
end

function wallConfig.GetMaxHp(groupIndex,wallIndex)
	local Group = wallConfig.Groups[groupIndex]
	if not Group then return 0 end
	return Group.HP[wallIndex]
end

function wallConfig.GetZoneNames(groupIndex)
	local group = wallConfig.Groups[groupIndex]
	return group and group.Name or "Unkown"
end

function wallConfig.GetWinReward(GroupIndex)
	local Group = wallConfig.Groups[GroupIndex]
	return Group and #Group.WinReward or 0
end

function wallConfig.GetWallCount(grpIndex)
	local Grop = wallConfig.Groups[grpIndex]
	return Grop and #Grop.HP or 0
end
-- NEw Code Ends here



-- Old Code 
--[[wallConfig.Groups = {
	{
		Name = "Wood_Zone",
		Healths = {10, 20, 30, 40, 50},
		WinReward = 2,
	},
	{
		Name = "Stone_Zone",
		Healths = {75, 100, 150, 200, 250},
		WinReward = 5,
	},
	{
		Name = "Iron_Zone",
		Healths = {300, 500, 500, 600, 300},
		WinReward = 10,
	},
	{
		Name = "Metal_Zone",
		Healths = {340, 380, 420, 460, 500},
		WinReward = 25,
	},
	{
		Name = "Zinc_Zone",
		Healths = {550, 600, 650, 700, 750},
		WinReward = 40,
	}
}

function wallConfig.GetMaxHP(groupIndex, wallIndex)
	local group = wallConfig.Groups[groupIndex]
	if group and group.Healths then
		return group.Healths[wallIndex] or 0
	end
	return 0
end]]

return wallConfig
