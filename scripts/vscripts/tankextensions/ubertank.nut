local UBERTANK_VALUES_TABLE = {
	UBERTANK_MODEL        = "models/bots/boss_bot/boss_tank_ubered.mdl"
	UBERTANK_SND_UBER     = "player/invulnerable_on.wav"
	UBERTANK_SND_UBER_OFF = "player/invulnerable_off.wav"
	UBERTANK_SKIN_UBER    = 2
}
foreach(k,v in UBERTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(UBERTANK_MODEL)
TankExt.PrecacheSound(UBERTANK_SND_UBER)
TankExt.PrecacheSound(UBERTANK_SND_UBER_OFF)

::UberTankEvents <- {
	OnGameEvent_recalculate_holidays = function(_) { if(GetRoundState() == 3) delete ::UberTankEvents }
	OnScriptHook_OnTakeDamage = function(params)
	{
		local hAttacker = params.attacker
		local hVictim   = params.const_entity
		if(hAttacker && hVictim && hVictim.GetClassname() == "tank_boss" && hAttacker.GetTeam() != hVictim.GetTeam())
		{
			local UberScope = TankExt.GetMultiScopeTable(hVictim.GetScriptScope(), "ubertank")
			if(UberScope && UberScope.bUbered)
			{
				params.damage = 0
				EmitSoundOn("FX_RicochetSound.Ricochet", hVictim)
			}
		}
	}
}
__CollectGameEventCallbacks(UberTankEvents)

TankExt.NewTankType("ubertank*", {
	function OnSpawn()
	{
		local sParams = split(sTankName, "|")
		if(sParams.len() == 1) sParams.append(0)
		if(sParams.len() == 2) sParams.append(30)

		local flTimeStart = sParams[1].tofloat()
		if(flTimeStart >= 0) TankExt.DelayFunction(self, this, flTimeStart, @() ToggleUber())

		local sModelLast  = null
		local flDuration  = sParams[2].tofloat()
		local iColorLast  = 0
		local iSkinLast   = 0
		local bUberFizzle = false
		bUbered <- false
		function ToggleUber()
		{
			if(!bUberFizzle)
				if(!bUbered)
				{
					if(flDuration >= 0) TankExt.DelayFunction(self, this, flDuration, @() ToggleUber())
					bUbered    = true
					sModelLast = self.GetModelName()
					iColorLast = GetPropInt(self, "m_clrRender")
					iSkinLast  = self.GetSkin()
					SetPropInt(self, "m_takedamage", DAMAGE_EVENTS_ONLY)
					self.AcceptInput("Color", "127 127 127", null, null)
					self.SetSkin(UBERTANK_SKIN_UBER)
					TankExt.SetTankModel(self, UBERTANK_MODEL)
					EmitSoundEx({
						sound_name  = UBERTANK_SND_UBER
						filter_type = RECIPIENT_FILTER_GLOBAL
					})
				}
				else
				{
					bUberFizzle = true
					EmitSoundEx({
						sound_name  = UBERTANK_SND_UBER_OFF
						filter_type = RECIPIENT_FILTER_GLOBAL
					})
					TankExt.DelayFunction(self, this, 1, function()
					{
						bUbered     = false
						bUberFizzle = false
						SetPropInt(self, "m_takedamage", DAMAGE_YES)
						SetPropInt(self, "m_clrRender", iColorLast)
						self.SetSkin(iSkinLast)
						TankExt.SetTankModel(self, sModelLast)
					})
				}
		}
		local UberScope = this
		self.GetScriptScope().ToggleUber <- @() UberScope.ToggleUber()

		function Think()
		{
			if(bUbered)
			{
				local sModel = self.GetModelName()
				if(sModel != UBERTANK_MODEL)
				{
					sModelLast = sModel
					TankExt.SetTankModel(self, UBERTANK_MODEL)
				}
			}
			if(bUberFizzle)
			{
				local flColor = 63.5 - sin(flTime * 20.95) * 63.5 // 20.95 == PI / 0.3 * 0.5
				self.AcceptInput("Color", format("%i %i %i", flColor, flColor, flColor), null, null)
			}
		}
	}
})