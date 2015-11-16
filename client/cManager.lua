class 'AirTrafficManager'

function AirTrafficManager:__init()

	self.npcs = {}
	
	-- Events:Subscribe("Render", self, self.Render) -- debug
	Events:Subscribe("EntitySpawn", self, self.EntitySpawn)
	Events:Subscribe("EntityDespawn", self, self.EntityDespawn)
	Events:Subscribe("VehicleCollide", self, self.VehicleCollide)
	Network:Subscribe("Unregister", self, self.Unregister)

end

function AirTrafficManager:Render()

	for _, npc in pairs(self.npcs) do
		if IsValid(npc) then
			math.randomseed(npc:GetModelId())
			local color = Color(math.random(255), math.random(255), math.random(255))
			Render:DrawCircle(Render:WorldToScreen(npc:GetTargetPosition()), 10, color)
			Render:DrawCircle(Render:WorldToScreen(npc:GetPosition()), 10, color)
		end
	end

end

function AirTrafficManager:VehicleCollide(args)
	
	if args.entity.__type == "Vehicle" and self.npcs[args.entity:GetId()] then
		Network:Send("Collision", {vehicle = args.entity})
	end
	
end

function AirTrafficManager:EntitySpawn(args)
	
	if args.entity.__type == "Vehicle" and args.entity:GetValue("P") then
		AirTrafficNPC(args)
	end

end

function AirTrafficManager:EntityDespawn(args)

	if args.entity.__type == "Vehicle" and self.npcs[args.entity:GetId()] then
		self.npcs[args.entity:GetId()]:Remove()
	end

end

function AirTrafficManager:Unregister(args)

	self.npcs[args.id]:Remove()

end

function AirTrafficManager:ModuleUnload()

	for _, npc in pairs(self.npcs) do
		npc:Remove()
	end

end

AirTrafficManager = AirTrafficManager()
