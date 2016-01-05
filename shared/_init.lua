settings = {
	debug = false,
	delay = 2, -- server update interval in seconds
	count = 1024, -- number of planes to initially spawn
	speeds = { -- plane cruise speeds in m/s
		[24] = 82, -- F-33 DragonFly
		[30] = 77, -- Si-47 Leopard
		[34] = 95, -- G9 Eclipse
		[39] = 90, -- Aeroliner 474
		[51] = 69, -- Cassius 192
		[59] = 56, -- Peek Airhawk 225
		[81] = 73, -- Pell Silverbolt 6
		[85] = 87, -- Bering I-86DP
	},
	pool = {39, 51, 59, 59, 81} -- which planes to spawn randomly
}
