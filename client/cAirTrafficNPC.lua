class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)

	self.vehicle = args.entity
	
	local angle = self:GetAngle()
	local position = self:GetPosition()
	local velocity = self:GetLinearVelocity()

	self.actor = ClientActor.Create(AssetLocation.Game, {
		model_id = 98,
		position = position,
		angle = angle
	})
	
	self.timers = {
		collision = Timer(),
		tick = Timer()
	}

	self.network_velocity = velocity
	self.network_position = position
	self.network_velocity_norm = velocity:Normalized()
	self.terrain_height = self:GetMaxTerrainHeight()

	self.speed = settings.speeds[self:GetModelId()]
	self.follow_distance = self.speed * settings.delay * 0.5

	self.vehicle:SetPosition(self:GetTargetPosition() - self.network_velocity_norm * self.follow_distance)

	self.loader = Events:Subscribe("PostTick", self, self.Load)

end

function AirTrafficNPC:Load()

	if IsValid(self.vehicle) then
	
		if IsValid(self.actor) then
			self.actor:EnterVehicle(self.vehicle, 0)
			Events:Unsubscribe(self.loader)
			self.loader = nil
			AirTrafficManager.npcs[self:GetId()] = self
		end

	else
	
		self.actor:Remove()
		Events:Unsubscribe(self.loader)
		self.loader = nil
	
	end

end

function AirTrafficNPC:Update(position)

	self.timers.tick:Restart()
	self.network_position = position
	self.terrain_height = self:GetMaxTerrainHeight()

end

function AirTrafficNPC:Tick(dt)

	if self.vehicle:GetHealth() <= 0.2 then return end

	local limit = 0.25 * math.pi
	local p1 = self:GetPosition()
	local p2 = self:GetTargetPosition()
	local p3 = p2 - self.network_velocity_norm * self.follow_distance

	local q_dir = p2 - p1
	local q_dp = q_dir:Length()

	local q1 = self:GetAngle(); q1.roll = 0
	local q2 = Angle(math.atan2(-q_dir.x, -q_dir.z), math.clamp(math.asin(q_dir.y / q_dp), -limit, limit), 0)
	local dq = q1:Delta(q2)

	local q = (IsNaN(dq) or dq == 0) and q1 or Angle.Slerp(q1, q2, 0.2 * dt / dq)
	self.vehicle:SetAngle(q)
	
	local v_dir = p3 - p1
	local v_dp = v_dir:Length()
	
	local v1 = self:GetLinearVelocity()
	local v2 = q * Vector3(0, 0, -self.speed) + math.min(v_dp, 0.5 * self.speed) * v_dir / v_dp
	local dv = v1:Distance(v2)
	
	local v = (IsNaN(dv) or dv == 0) and v1 or math.lerp(v1, v2, 10 * dt / dv)
	self.vehicle:SetLinearVelocity(v)

end

function AirTrafficNPC:CollisionResponse()

	if self.timers.collision:GetMilliseconds() > 500 then
		self.timers.collision:Restart()
		Network:Send("Collision", {id = self:GetId()})
	end

end

function AirTrafficNPC:GetPosition()
	return self.vehicle:GetPosition()
end

function AirTrafficNPC:GetAngle()
	return self.vehicle:GetAngle()
end

function AirTrafficNPC:GetTargetPosition()

	local p = self.network_position + self.network_velocity * self.timers.tick:GetSeconds()
	p.y = p.y + self.terrain_height + 200
	return p

end

function AirTrafficNPC:GetMaxTerrainHeight()

	local p = self:GetPosition()
	local v = self.network_velocity_norm
	local h = 200

	for i = 0, 512, 16 do
		h = math.max(h, Physics:GetTerrainHeight(p + v * i))
	end

	return h

end

function AirTrafficNPC:GetNetworkPosition()
	return self:GetTargetPosition() - self.network_velocity * self.timers.tick:GetSeconds()
end

function AirTrafficNPC:GetLinearVelocity()
	return self.vehicle:GetLinearVelocity()
end

function AirTrafficNPC:GetModelId()
	return self.vehicle:GetModelId()
end

function AirTrafficNPC:GetId()
	return self.vehicle:GetId()
end

function AirTrafficNPC:IsValid()
	return IsValid(self.vehicle) and IsValid(self.actor)
end

function AirTrafficNPC:Remove()

	AirTrafficManager.npcs[self:GetId()] = nil
	self.actor:Remove()

end
