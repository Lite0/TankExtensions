local PARATANK_VALUES_TABLE = {
	PARATANK_PARACHUTE_MODEL = "models/props_aircrap/tank_chute.mdl"
	PARATANK_SND_PARACHUTE_OPEN = "items/para_open.wav"
	PARATANK_SND_PARACHUTE_CLOSE = "items/para_close.wav"
}
foreach(k,v in PARATANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheSound(PARATANK_SND_PARACHUTE_OPEN)
PrecacheSound(PARATANK_SND_PARACHUTE_CLOSE)

TankExt.NewTankScript("paratank", {
	OnSpawn = function(hTank, sName, hPath)
	{
		local hTank_scope = hTank.GetScriptScope()
		local flSpeed = GetPropFloat(hTank, "m_speed")
		hTank_scope.hTrackTrain <- SpawnEntityFromTable("func_tracktrain", {
			origin = hTank.GetOrigin()
			speed = flSpeed
			startspeed = flSpeed
			target = hPath.GetName()
		})
		hTank_scope.hParachute <- SpawnEntityFromTable("prop_dynamic", { model = PARATANK_PARACHUTE_MODEL })
		TankExt.SetParentArray([hTank_scope.hParachute], hTank)
		hTank_scope.flLastSpeed <- flSpeed
		hTank_scope.bParachuteActive <- false
		hTank_scope.Think <- function()
		{
			local vecOrigin = self.GetOrigin()
			local vecTrackTrain = hTrackTrain.GetOrigin()
			local SetTrackAnim = function(sAnim)
			{
				for(local hChild = hTank.FirstMoveChild(); hChild != null; hChild = hChild.NextMovePeer())
					if(hChild.GetModelName().find("tank_track"))
						EntFireByHandle(hChild, "SetAnimation", sAnim, -1, null, null)
			}
			
			if(!bParachuteActive)
			{
				hTrackTrain.SetAbsOrigin(vecOrigin)
				local hNextPath = GetPropEntity(GetPropEntity(hTrackTrain, "m_ppath"), "m_pnext")
				if(hNextPath)
				{
					local vecOriginXY = Vector(vecOrigin.x, vecOrigin.y, 0)
					local vecNextPathXY = hNextPath.GetOrigin()
					vecNextPathXY.z = 0
					if((vecOriginXY - vecNextPathXY).Length() <= 16)
						SetPropEntity(hTrackTrain, "m_ppath", hNextPath)
				}
			}
			else
			{
				self.SetAbsOrigin(vecTrackTrain)
				self.GetLocomotionInterface().Reset()
			}

			local Trace = {
				start = vecOrigin
				end = vecOrigin + Vector(0, 0, -32)
				ignore = self
				mask = MASK_NPCSOLID_BRUSHONLY
			}
			TraceLineEx(Trace)
			if(!Trace.hit && !bParachuteActive)
			{
				bParachuteActive = true
				self.SetAbsAngles(QAngle(0, self.GetAbsAngles().y, 0))
				EntFireByHandle(hParachute, "SetAnimation", "deploy", -1, null, null)
				SetTrackAnim("ref")
				EmitSoundEx({
					sound_name = PARATANK_SND_PARACHUTE_OPEN
					filter_type = RECIPIENT_FILTER_GLOBAL
					pitch = 85
				})
			}
			else if(Trace.hit && bParachuteActive)
			{
				bParachuteActive = false
				EntFireByHandle(hParachute, "SetAnimation", "retract", -1, null, null)
				SetTrackAnim("forward")
				EmitSoundEx({
					sound_name = PARATANK_SND_PARACHUTE_CLOSE
					filter_type = RECIPIENT_FILTER_GLOBAL
					pitch = 85
				})
			}

			local flSpeed = GetPropFloat(self, "m_speed")
			if(flSpeed == 0) flSpeed = 0.001
			if(flSpeed != flLastSpeed)
			{
				flLastSpeed = flSpeed
				SetPropFloat(hTrackTrain, "m_flSpeed", flSpeed)
			}
			return -1
		}
		AddThinkToEnt(hTank, "Think")
	}
	OnDeath = function()
	{
		if(hTrackTrain && hTrackTrain.IsValid()) hTrackTrain.Destroy()
	}
})