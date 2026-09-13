local wallConfig = {}

wallConfig.Groups = {
	{
		Name = "Wood_Zone",
		Healths = {10,20,30,40,50},
		WinReward = 2,
	},
	{
		Name = "Stone_Zone",
		Healths = {70,90,110,130,150},
		WinReward = 5,
	},
	{
		Name = "Iron_Zone",
		Healths = {180,210,240,270,300},
		WinReward = 10,
	},
	{
		Name = "Metal_Zone",
		Healths = {340,380,420,460,500},
		WinReward = 25,
	},
	{
		Name = "Zinc_Zone",
		Healths = {550,600,650,700,750},
		WinReward = 40,
	}
}

return wallConfig
