class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)
	
	self.vehicle = Vehicle.Create(args)

	AirTrafficManager.npcs[self.vehicle:GetId()] = self
	AirTrafficManager.count = AirTrafficManager.count + 1

	self.vehicle:SetNetworkValue("ATP", true)

	self.timers = {tick = Timer()}

end

function AirTrafficNPC:Tick()

	local vehicle = self.vehicle
	local p = vehicle:GetPosition()

	if p.x > 16384 then
		p.x = -16384
	elseif p.x < -16384 then
		p.x = 16384
	elseif p.z > 16384 then
		p.z = -16384
	elseif p.z < -16384 then
		p.z = 16384
	end
	
	p = p + vehicle:GetLinearVelocity() * self.timers.tick:GetSeconds()
	vehicle:SetStreamPosition(p)
	
	if self:IsStreamed() then
		
		vehicle:SetNetworkValue("ATP", p)
		
		if not self.destroyed and vehicle:GetHealth() <= 0.2 then
				
			if not self.timers.removal then
				self.timers.removal = Timer()
			elseif self.timers.removal:GetSeconds() > 5 then
				self.destroyed = true
				table.insert(AirTrafficManager.removals, self)
			end

		end
		
	end

	self.timers.tick:Restart()

end

function AirTrafficNPC:IsStreamed()

	for player in self.vehicle:GetStreamedPlayers() do
		return true
	end
	return false

end

function AirTrafficNPC:Remove()

	AirTrafficManager.npcs[self.vehicle:GetId()] = nil
	AirTrafficManager.count = AirTrafficManager.count - 1
	if IsValid(self.vehicle) then self.vehicle:Remove() end

end
