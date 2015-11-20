class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)
	
	self.vehicle = Vehicle.Create(args)

	AirTrafficManager.npcs[self.vehicle:GetId()] = self
	
	self.position = args.position
	self.linear_velocity = args.linear_velocity

	self.timer = Timer()

	self.vehicle:SetNetworkValue("P", self.position)
	self.vehicle:SetNetworkValue("V", self.linear_velocity)
	
	self.tick = Events:Subscribe("PostTick", self, self.PostTick)

end

function AirTrafficNPC:PostTick(args)

	local dt = self.timer:GetSeconds()
	
	if dt > 0.5 and IsValid(self.vehicle) then
	
		self.timer:Restart()
		
		local p = self.position
	
		if p.x > 16384 then
			p.x = -16384
		elseif p.x < -16384 then
			p.x = 16384
		elseif p.z > 16384 then
			p.z = -16384
		elseif p.z < -16384 then
			p.z = 16384
		end
		
		self:SetPosition(p + self.linear_velocity * dt)

	end

end

function AirTrafficNPC:SetPosition(position)

	self.position = position
	self.vehicle:SetStreamPosition(position)
	self.vehicle:SetNetworkValue("P", position)

end

function AirTrafficNPC:Remove()

	Events:Unsubscribe(self.tick)
	AirTrafficManager.npcs[self.vehicle:GetId()] = nil
	if IsValid(self.vehicle) then self.vehicle:Remove() end

end
