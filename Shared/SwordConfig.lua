local SwordConfig = {}

-- Boss Drop swords can only be obtained from the Boss Event

SwordConfig.Swords = {
	{Name = "Rusty Blade",      Cost = 0,               multi = 1.0,          },
	{Name = "Iron  Blade",      Cost = 500,             multi = 1.5           },
	{Name = "Void  Blade",      Cost = 0,               multi = 7.0,         BossDrop = true}
}


return SwordConfig
