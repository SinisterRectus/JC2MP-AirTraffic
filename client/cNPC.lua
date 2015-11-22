class 'AirTrafficNPC'

function AirTrafficNPC:__init(args)

	self.vehicle = args.entity
	
	AirTrafficManager.npcs[self:GetId()] = self

	self.actor = ClientActor.Create(AssetLocation.Game, {
		model_id = 98,
		position = self:GetPosition(),
		angle = self:GetAngle()
	})
	
	self.vehicle:SetLinearVelocity(self:GetTargetLinearVelocity())
	self.vehicle:SetPosition(self:GetTargetPosition() + self:GetAngle() * Vector3.Backward * 100)

	self.timer = Timer()
	
	self.tick = Events:Subscribe("PostTick", self, self.Load)

end

function AirTrafficNPC:Load()

	if IsValid(self.actor) then
		self.actor:EnterVehicle(self.vehicle, 0)
		Events:Unsubscribe(self.tick)
		self.tick = Events:Subscribe("PostTick", self, self.Control)
	end

end

function AirTrafficNPC:Control()

	local deg = math.deg
	local abs = math.abs
	local clamp = math.clamp
	
	local angle = self:GetAngle()
	local position = self:GetPosition()
	local target_position = self:GetTargetPosition()

	local d = position - target_position
	local distance = d:Length()

	local yaw = deg(angle.yaw)
	local heading = yaw < 0 and -yaw or 360 - yaw
	local roll = deg(angle.roll)
	local pitch = deg(angle.pitch)
	local speed = self:GetLinearVelocity():Length()

	local target_yaw = deg(math.atan2(d.x, d.z))
	local target_heading = target_yaw < 0 and -target_yaw or 360 - target_yaw
	local target_roll = clamp(((heading - target_heading + 180) % 360 - 180) * 2.0, -45, 45)
	local target_pitch = clamp(deg(math.asin(-d.y / distance)), -45, 45)
	local target_speed = distance / 100 * self:GetTargetLinearVelocity():Length()

	local roll_input = clamp(abs(roll - target_roll) * 0.2, 0, 0.7)
	local pitch_input = clamp(abs(pitch - target_pitch) * 0.5, 0, 0.7)
	local speed_input = clamp(abs(speed - target_speed) * 0.05, 0, 0.7)
		
	if target_roll < roll then
		self.actor:SetInput(Action.PlaneTurnRight, roll_input)
	else
		self.actor:SetInput(Action.PlaneTurnLeft, roll_input)
	end
	
	if abs(roll) < 60 then
		if target_pitch > pitch then
			self.actor:SetInput(Action.PlanePitchUp, pitch_input)
		else
			self.actor:SetInput(Action.PlanePitchDown, pitch_input)
		end
	elseif abs(roll) > 120 then
		if target_pitch > pitch then
			self.actor:SetInput(Action.PlanePitchDown, pitch_input)
		else
			self.actor:SetInput(Action.PlanePitchUp, pitch_input)
		end
	end
	
	if target_speed > speed then
		self.actor:SetInput(Action.PlaneIncTrust, speed_input)
	else
		self.actor:SetInput(Action.PlaneDecTrust, speed_input)
	end

end

function AirTrafficNPC:CollisionResponse()

	if self.timer:GetMilliseconds() > 500 then
		self.timer:Restart()
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

	local p = self.vehicle:GetValue("P")
	local h = Physics:GetTerrainHeight(p)
	
	if h > 1500 then
		p.y = p.y + 2500
	elseif h > 1000 then
		p.y = p.y + 1500
	elseif h > 500 then
		p.y = p.y + 1000
	elseif h > 250 then
		p.y = p.y + 750
	else
		p.y = p.y + 500
	end
	
	return p

end

function AirTrafficNPC:GetTargetLinearVelocity()
	return self.vehicle:GetValue("V")
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

	Events:Unsubscribe(self.tick)
	AirTrafficManager.npcs[self:GetId()] = nil
	self.actor:Remove()

end
