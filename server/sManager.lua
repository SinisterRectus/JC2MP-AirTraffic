class 'AirTrafficManager'

function AirTrafficManager:__init()

	self.delay = 0.5
	self.timer = Timer()
	
	self.npcs = {}
	self.count = 0
	
	self.models = {
		civilian = {39, 51, 59, 81},
		military = {30, 34, 85},
	}
	
	self.speeds = {
		[24] = 82, -- F-33 DragonFly
		[30] = 77, -- Si-47 Leopard
		[34] = 95, -- G9 Eclipse
		[39] = 90, -- Aeroliner 474
		[51] = 69, -- Cassius 192
		[59] = 56, -- Peek Airhawk 225
		[81] = 73, -- Pell Silverbolt 6
		[85] = 87, -- Bering I-86DP
	}
	
	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("EntityDespawn", self, self.EntityDespawn)
	Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)
	Network:Subscribe("Collision", self, self.Collision)

end

function AirTrafficManager:ModuleLoad()

	local timer = Timer()
	
	for i = 1, 1024 do
		self:SpawnRandomNPC()
	end
	
	self.co = coroutine.create(function()
		while true do
			for _, npc in pairs(self.npcs) do
				npc:Tick()
				coroutine.yield()
			end
		end
	end)
	
	Events:Subscribe("PostTick", self, self.PostTick)

	print(string.format("Air traffic loaded in %i ms", timer:GetMilliseconds()))

end

function AirTrafficManager:PostTick(args)

	for i = 1, math.clamp(args.delta * self.count / self.delay, 1, self.count) do
		coroutine.resume(self.co)
	end

end

function AirTrafficManager:Collision(args)

	self.npcs[args.id]:Remove()
	self:SpawnRandomNPC()

end

function AirTrafficManager:EntityDespawn(args)

	if self.unloading then return end
	if args.entity.__type ~= "Vehicle" then return end

	local id = args.entity:GetId()
	if not self.npcs[id] then return end

	self.npcs[id] = nil
	self.count = self.count - 1

end

function AirTrafficManager:PlayerEnterVehicle(args)

	local id = args.vehicle:GetId()
	if not self.npcs[id] then return end

	self.npcs[id] = nil
	self.count = self.count - 1
		
	local players = {}
	for player in args.vehicle:GetStreamedPlayers() do
		table.insert(players, player)
	end

	Network:SendToPlayers(players, "Unregister", {id = id})
	
	args.vehicle:SetNetworkValue("P", nil)
	args.vehicle:SetNetworkValue("V", nil)
	
	self:SpawnRandomNPC()

end

function AirTrafficManager:SpawnRandomNPC()

	local angle = Angle(math.pi * 0.1 * math.random(-10, 10), 0, 0)
	local model_id = table.randomvalue(self.models.civilian)

	AirTrafficNPC({
		model_id = model_id,
		position = Vector3(math.random(-16384, 16384), math.random(0, 100), math.random(-16384, 16384)),
		angle = angle,
		linear_velocity = angle * Vector3.Forward * self.speeds[model_id]
	})

end

function AirTrafficManager:ModuleUnload()

	self.unloading = true

	for _, npc in pairs(self.npcs) do
		npc:Remove()
	end

end

AirTrafficManager = AirTrafficManager()
