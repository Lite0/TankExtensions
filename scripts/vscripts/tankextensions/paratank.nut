local PARATANK_VALUES_TABLE = {
	PARATANK_PARACHUTE_MODEL     = "models/props_aircrap/tank_chute.mdl"
	PARATANK_SND_PARACHUTE_OPEN  = ")items/para_open.wav"
	PARATANK_SND_PARACHUTE_CLOSE = ")items/para_close.wav"
	PARATANK_GROUND_DISTANCE     = -32
}
foreach(k,v in PARATANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(PARATANK_PARACHUTE_MODEL)
TankExt.PrecacheSound(PARATANK_SND_PARACHUTE_OPEN)
TankExt.PrecacheSound(PARATANK_SND_PARACHUTE_CLOSE)

TankExt.NewTankType("paratank", {
	function OnSpawn()
	{
		local flSpeed = GetPropFloat(self, "m_speed")
		hTrackTrain <- SpawnEntityFromTable("func_tracktrain", {
			origin     = self.GetOrigin()
			speed      = flSpeed
			startspeed = flSpeed
			target     = hTankPath.GetName()
		})

		local hParachute = TankExt.SpawnEntityFromTableFast("prop_dynamic", { model = PARATANK_PARACHUTE_MODEL })
		hParachute.DisableDraw()
		TankExt.SetParentArray([hParachute], self)

		local hTracks = []
		for(local hChild = self.FirstMoveChild(); hChild != null; hChild = hChild.NextMovePeer())
			if(hChild.GetModelName().find("track_"))
				hTracks.append(hChild)

		local flLastSpeed      = flSpeed
		local bParachuteActive = false
		local hTank_scope      = self.GetScriptScope()
		local iSeqRetract      = hParachute.LookupSequence("retract")
		function Think()
		{
			local vecTrackTrain = hTrackTrain.GetOrigin()

			if(!bParachuteActive)
			{
				hTrackTrain.SetAbsOrigin(vecOrigin)
				local hNextPath = GetPropEntity(GetPropEntity(hTrackTrain, "m_ppath"), "m_pnext")
				if(hNextPath && (vecOrigin - hNextPath.GetOrigin()).Length2DSqr() <= 256) // sqr(16)
					SetPropEntity(hTrackTrain, "m_ppath", hNextPath)
			}
			else
			{
				self.SetAbsOrigin(vecTrackTrain)
				self.GetLocomotionInterface().Reset()
				foreach(hTrack in hTracks)
					hTrack.SetPlaybackRate(0)
			}

			local Trace = {
				start  = vecOrigin
				end    = vecOrigin + Vector(0, 0, PARATANK_GROUND_DISTANCE)
				ignore = self
				mask   = MASK_NPCSOLID_BRUSHONLY
			}
			TraceLineEx(Trace)
			if(!Trace.hit && !bParachuteActive)
			{
				bParachuteActive = true
				hParachute.EnableDraw()
				hParachute.AcceptInput("SetAnimation", "deploy", null, null)
				self.SetAbsAngles(QAngle(0, self.GetAbsAngles().y, 0))
				EmitSoundEx({
					sound_name  = "EngineLoopSound" in hTank_scope ? hTank_scope.EngineLoopSound : "MVM.TankEngineLoop"
					channel     = CHAN_STATIC
					entity      = self
					filter_type = RECIPIENT_FILTER_GLOBAL
					flags       = SND_STOP
				})
				EmitSoundEx({
					sound_name  = PARATANK_SND_PARACHUTE_OPEN
					filter_type = RECIPIENT_FILTER_GLOBAL
					pitch       = 85
				})
			}
			else if(Trace.hit && bParachuteActive)
			{
				bParachuteActive = false
				hParachute.AcceptInput("SetAnimation", "retract", null, null)
				EmitSoundEx({
					sound_name  = "EngineLoopSound" in hTank_scope ? hTank_scope.EngineLoopSound : "MVM.TankEngineLoop"
					channel     = CHAN_STATIC
					sound_level = 85
					entity      = self
					filter_type = RECIPIENT_FILTER_GLOBAL
				})
				EmitSoundEx({
					sound_name  = PARATANK_SND_PARACHUTE_CLOSE
					filter_type = RECIPIENT_FILTER_GLOBAL
					pitch       = 85
				})
			}
			if(hParachute.GetSequence() == iSeqRetract && hParachute.GetCycle() == 1) hParachute.DisableDraw()

			local flSpeed = GetPropFloat(self, "m_speed")
			if(flSpeed == 0) flSpeed = 0.0001
			if(flSpeed != flLastSpeed)
			{
				flLastSpeed = flSpeed
				SetPropFloat(hTrackTrain, "m_flSpeed", flSpeed)
			}
		}
	}
	function OnDeath()
	{
		if(hTrackTrain && hTrackTrain.IsValid()) hTrackTrain.Destroy()
	}
})