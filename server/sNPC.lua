class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)
	
	self.vehicle = Vehicle.Create(args)

	AirTrafficManager.npcs[self.vehicle:GetId()] = self
	
	self.position = args.position
	self.angle = args.angle
	self.linear_velocity = args.linear_velocity

	self.timer = Timer()

	self.vehicle:SetNetworkValue("P", self.position)
	self.vehicle:SetNetworkValue("V", self.linear_velocity)
	
	self.subs = {
		Events:Subscribe("PostTick", self, self.PostTick)
	}

end

function AirTrafficNPC:PostTick(args)

	local dt = self.timer:GetSeconds()
	
	if dt > 0.5 and IsValid(self.vehicle) then
	
		self.timer:Restart()
	
		if self.position.x > 16384 then
			self.position.x = -16384
		elseif self.position.x < -16384 then
			self.position.x = 16384
		elseif self.position.z > 16384 then
			self.position.z = -16384
		elseif self.position.z < -16384 then
			self.position.z = 16384
		end
		
		self:SetPosition(self.position + self.linear_velocity * dt)

	end

end

function AirTrafficNPC:SetPosition(position)

	self.position = position
	self.vehicle:SetStreamPosition(position)
	self.vehicle:SetNetworkValue("P", position)

end

function AirTrafficNPC:Remove()

	for _, sub in ipairs(self.subs) do
		Events:Unsubscribe(sub)
	end
	
	AirTrafficManager.npcs[self.vehicle:GetId()] = nil
	if IsValid(self.vehicle) then self.vehicle:Remove() end

end
