class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)
	
	self.vehicle = Vehicle.Create(args)

	AirTrafficManager.npcs[self.vehicle:GetId()] = self
	AirTrafficManager.count = AirTrafficManager.count + 1
	
	self.position = args.position
	self.linear_velocity = args.linear_velocity

	self.vehicle:SetNetworkValue("P", args.position)
	self.vehicle:SetNetworkValue("V", args.linear_velocity)

	self.timer = Timer()

end

function AirTrafficNPC:Tick()
	
	local dt = self.timer:GetSeconds()
	
	if dt > 0.9 * AirTrafficManager.delay then
		
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
		self.timer:Restart()
		
	end

end

function AirTrafficNPC:SetPosition(position)

	self.position = position
	self.vehicle:SetStreamPosition(position)
	self.vehicle:SetNetworkValue("P", position)

end

function AirTrafficNPC:Remove()

	AirTrafficManager.npcs[self.vehicle:GetId()] = nil
	AirTrafficManager.count = AirTrafficManager.count - 1
	if IsValid(self.vehicle) then self.vehicle:Remove() end

end
