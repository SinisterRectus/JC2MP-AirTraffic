class 'AirTrafficManager'

function AirTrafficManager:__init()

	self.timer = Timer()
	
	self.npcs = {}
	self.count = 0
	
	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("EntityDespawn", self, self.EntityDespawn)
	Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)
	Events:Subscribe("PlayerExitVehicle", self, self.PlayerExitVehicle)
	Network:Subscribe("Collision", self, self.Collision)

end

function AirTrafficManager:ModuleLoad()

	local timer = Timer()
	
	for i = 1, settings.count do
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

	local count = self.count
	local delay = settings.delay

	local n = math.min(args.delta * count / delay, count)
	
	if n > 1 then

		for i = 1, n do
			coroutine.resume(self.co)
		end
		
	elseif self.timer:GetSeconds() > delay / count then

		self.timer:Restart()
		coroutine.resume(self.co)
	
	end

end

function AirTrafficManager:Collision(args)

	local npc = self.npcs[args.id]
	if not npc then return end

	npc:Remove()

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

	if not args.is_driver then return end
	local id = args.vehicle:GetId()
	if not self.npcs[id] then return end

	self.npcs[id] = nil
	self.count = self.count - 1
	
	args.vehicle:SetNetworkValue("P", nil)
	args.vehicle:SetValue("Hijacked", true)
	
	self:SpawnRandomNPC()

end

function AirTrafficManager:PlayerExitVehicle(args)

	if not args.vehicle:GetValue("Hijacked") then return end
	if #args.vehicle:GetOccupants() > 0 then return end
	args.vehicle:Remove()

end

function AirTrafficManager:SpawnRandomNPC()

	local angle = Angle(math.pi * 0.1 * math.random(-10, 10), 0, 0)
	local model_id = table.randomvalue(settings.pool)
	
	AirTrafficNPC({
		model_id = model_id,
		position = Vector3(math.random(-16384, 16384), math.random(0, 100), math.random(-16384, 16384)),
		angle = angle,
		linear_velocity = angle * Vector3.Forward * settings.speeds[model_id]
	})

end

function AirTrafficManager:ModuleUnload()

	self.unloading = true

	for _, npc in pairs(self.npcs) do
		npc:Remove()
	end

end

AirTrafficManager = AirTrafficManager()
