class 'AirTrafficManager'

function AirTrafficManager:__init()
	
	self.npcs = {}

	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("EntityDespawn", self, self.Unregister)
	Events:Subscribe("PlayerEnterVehicle", self, self.Unregister)
	Network:Subscribe("Collision", self, self.Collision)

end

function AirTrafficManager:ModuleLoad()

	local timer = Timer()

	local models = {
		civilian = {39, 51, 59, 81},
		military = {30, 34, 85},
	}

	local speeds = {
		[24] = 82, -- F-33 DragonFly
		[30] = 77, -- Si-47 Leopard
		[34] = 95, -- G9 Eclipse
		[39] = 90, -- Aeroliner 474
		[51] = 69, -- Cassius 192
		[59] = 56, -- Peek Airhawk 225
		[81] = 73, -- Pell Silverbolt 6
		[85] = 87, -- Bering I-86DP
	}
	
	for i = 1, 512 do
	
		local angle = Angle(math.pi * 0.1 * math.random(-10, 10), 0, 0)
		local model_id = table.randomvalue(models.civilian)
	
		AirTrafficNPC({
			model_id = model_id,
			position = Vector3(math.random(-16384, 16384), 0, math.random(-16384, 16384)),
			angle = angle,
			linear_velocity = angle * Vector3.Forward * speeds[model_id]
		})

	end

	print(string.format("Air traffic loaded in %i ms", timer:GetMilliseconds()))

end

function AirTrafficManager:Collision(args)

	if not IsValid(args.vehicle) then return end
	self.npcs[args.vehicle:GetId()]:SetPosition(args.vehicle:GetSpawnPosition())

end

function AirTrafficManager:Unregister(args)

	if self.unloading then return end
	args.vehicle = args.vehicle or args.entity.__type == "Vehicle" and args.entity
	if not args.vehicle then return end
	local id = args.vehicle:GetId()
	if not self.npcs[id] then return end

	for _, sub in ipairs(self.npcs[id].subs) do
		Events:Unsubscribe(sub)
	end
	
	self.npcs[id] = nil
	
	local players = {}
	for player in args.vehicle:GetStreamedPlayers() do
		table.insert(players, player)
	end

	Network:SendToPlayers(players, "Unregister", {id = id})

end

function AirTrafficManager:ModuleUnload()

	self.unloading = true

	for _, npc in pairs(self.npcs) do
		npc:Remove()
	end

end

AirTrafficManager = AirTrafficManager()
