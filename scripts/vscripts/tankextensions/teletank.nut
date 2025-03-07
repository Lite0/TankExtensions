local TELETANK_VALUES_TABLE = {
	TELETANK_UBER_DURATION_MULT = 1
}
foreach(k,v in TELETANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

::TeleTankEvents <- {
	OnGameEvent_recalculate_holidays = function(_) { if(GetRoundState() == 3) delete ::TeleTankEvents }
	flLastTeleportTime = 0
	OnGameEvent_player_spawn = function(params)
	{
		local hPlayer = GetPlayerFromUserID(params.userid)
		EntFire("bignet", "RunScriptCode", "TeleTankEvents.Bot_TeleTank(activator)", -1, hPlayer)
	}
	Bot_TeleTank = function(hPlayer)
	{
		if(hPlayer.IsBotOfType(TF_BOT_TYPE) && hPlayer.HasBotTag("bot_teletank"))
			for(local hTank; hTank = FindByClassname(hTank, "tank_boss");)
			{
				local TeleScope = TankExt.GetMultiScopeTable(hTank.GetScriptScope(), "teletank")
				if(TeleScope && TeleScope.hTeleporter && TeleScope.hTeleporter.IsValid())
				{
					local vecTeleport = TeleScope.hTeleporter.GetOrigin() + TeleScope.hTeleporter.GetUpVector() * 16
					local Trace = {
						start   = vecTeleport
						end     = vecTeleport
						hullmin = hPlayer.GetBoundingMins()
						hullmax = hPlayer.GetBoundingMaxs()
						mask    = MASK_PLAYERSOLID_BRUSHONLY
						ignore  = hPlayer
					}
					TraceHull(Trace)
					if(!("startsolid" in Trace))
					{
						local flTime = Time()
						if(flTime - flLastTeleportTime > 0.1)
						{
							TeleScope.hTeleporter.EmitSound("MVM.Robot_Teleporter_Deliver")
							DispatchParticleEffect(hTank.GetTeam() == TF_TEAM_BLUE ? "teleportedin_blue" : "teleportedin_red", vecTeleport, Vector(1))
							flLastTeleportTime = flTime
						}

						hPlayer.SetAbsOrigin(vecTeleport)
						local flUberTime = Convars.GetFloat("tf_mvm_engineer_teleporter_uber_duration") * TELETANK_UBER_DURATION_MULT
						hPlayer.AddCondEx(TF_COND_INVULNERABLE, flUberTime, null)
						hPlayer.AddCondEx(TF_COND_INVULNERABLE_WEARINGOFF, flUberTime, null)
						hPlayer.AddCondEx(TF_COND_TELEPORTED, 30, null)
						break
					}
				}
			}
	}
}
__CollectGameEventCallbacks(TeleTankEvents)

TankExt.NewTankType("teletank", {
	function OnSpawn()
	{
		local bBlueTeam = self.GetTeam() == TF_TEAM_BLUE
		hTeleporter <- TankExt.SpawnEntityFromTableFast("prop_dynamic", {
			model          = "models/buildables/teleporter_light.mdl"
			defaultanim    = "running"
			body           = 1
			skin           = bBlueTeam ? 1 : 0
			origin         = "-42 0 169"
			disableshadows = 1
		})
		EmitSoundOn("Building_Teleporter.SpinLevel3", hTeleporter)
		TankExt.SetDestroyCallback(hTeleporter, @() StopSoundOn("Building_Teleporter.SpinLevel3", self))
		TankExt.DispatchParticleEffectOn(hTeleporter, bBlueTeam ? "teleporter_arms_circle_blue" : "teleporter_arms_circle_red", "arm_attach_L")
		TankExt.DispatchParticleEffectOn(hTeleporter, bBlueTeam ? "teleporter_arms_circle_blue" : "teleporter_arms_circle_red", "arm_attach_R")
		TankExt.SetParentArray([hTeleporter], self)
	}
})