class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)
	
	self.vehicle = Vehicle.Create(args)

	AirTrafficManager.npcs[self.vehicle:GetId()] = self
	AirTrafficManager.count = AirTrafficManager.count + 1

	self.vehicle:SetNetworkValue("P", true)

	self.timer = Timer()

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
	
	p = p + vehicle:GetLinearVelocity() * self.timer:GetSeconds()
	
	vehicle:SetStreamPosition(p)
	
	if self:IsStreamed() then

		vehicle:SetNetworkValue("P", p)

		local health = vehicle:GetHealth()
		if health == 0 then
			self:Remove()
			AirTrafficManager:SpawnRandomNPC()
		elseif health <= 0.2 then
			vehicle:SetHealth(0)
		end

	end
	
	self.timer:Restart()

end

function AirTrafficNPC:SetPosition(position)

	self.vehicle:SetStreamPosition(position)
	
	if self:IsStreamed() then
		self.vehicle:SetNetworkValue("P", position)
	end

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
