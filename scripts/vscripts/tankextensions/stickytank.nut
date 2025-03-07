local STICKYTANK_VALUES_TABLE = {
	STICKYTANK_TURRET_MODEL             = "models/props_frontline/tank_turret.mdl"
	STICKYTANK_SND_SHOOT_CRIT           = ")weapons/stickybomblauncher_shoot_crit.wav"
	STICKYTANK_SND_SHOOT                = ")weapons/stickybomblauncher_shoot.wav"
	STICKYTANK_PROJECTILE_MODEL         = "models/weapons/w_models/w_stickybomb.mdl"
	STICKYTANK_PROJECTILE_SPREAD        = 25
	STICKYTANK_PROJECTILE_SPLASH_RADIUS = 189
	STICKYTANK_PROJECTILE_SPEED         = 525
	STICKYTANK_PROJECTILE_DAMAGE        = 105
}
foreach(k,v in STICKYTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(STICKYTANK_TURRET_MODEL)
PrecacheModel(STICKYTANK_PROJECTILE_MODEL)
TankExt.PrecacheSound(STICKYTANK_SND_SHOOT)
TankExt.PrecacheSound(STICKYTANK_SND_SHOOT_CRIT)

TankExt.NewTankType("stickytank", {
	function OnSpawn()
	{
		local bBlueTeam = self.GetTeam() == TF_TEAM_BLUE
		local hModel1   = TankExt.SpawnEntityFromTableFast("prop_dynamic", { origin = "-16 -66 108", angles = "-58.5 0 -90", model = STICKYTANK_TURRET_MODEL, skin = bBlueTeam ? 2 : 0 })
		local hModel2   = TankExt.SpawnEntityFromTableFast("prop_dynamic", { origin = "-16 66 108", angles = "-58.5 0 90", model = STICKYTANK_TURRET_MODEL, skin = bBlueTeam ? 2 : 0 })
		local hMimic1   = SpawnEntityFromTable("tf_point_weapon_mimic", { origin = "51 57 217", angles = "-58.5 0 0", damage = STICKYTANK_PROJECTILE_DAMAGE, modelscale = 1, modeloverride = STICKYTANK_PROJECTILE_MODEL, speedmax = STICKYTANK_PROJECTILE_SPEED, speedmin = STICKYTANK_PROJECTILE_SPEED, splashradius = STICKYTANK_PROJECTILE_SPLASH_RADIUS, weapontype = 3, spreadangle = STICKYTANK_PROJECTILE_SPREAD })
		local hMimic2   = SpawnEntityFromTable("tf_point_weapon_mimic", { origin = "51 -57 217", angles = "-58.5 0 0", damage = STICKYTANK_PROJECTILE_DAMAGE, modelscale = 1, modeloverride = STICKYTANK_PROJECTILE_MODEL, speedmax = STICKYTANK_PROJECTILE_SPEED, speedmin = STICKYTANK_PROJECTILE_SPEED, splashradius = STICKYTANK_PROJECTILE_SPLASH_RADIUS, weapontype = 3, spreadangle = STICKYTANK_PROJECTILE_SPREAD })
		TankExt.SetParentArray([hMimic1, hMimic2, hModel1, hModel2], self)

		local ShootStickies = function(iStickyCount = 1, bCrit = false)
		{
			if(!(hMimic1 && hMimic1.IsValid() && hMimic2 && hMimic2.IsValid()))
				return

			local sMultiple    = iStickyCount > 1 ? "FireMultiple" : "FireOnce"
			local sStickyCount = iStickyCount.tostring()
			SetPropBool(hMimic1, "m_bCrits", bCrit)
			SetPropBool(hMimic2, "m_bCrits", bCrit)
			hMimic1.AcceptInput(sMultiple, sStickyCount, null, null)
			hMimic2.AcceptInput(sMultiple, sStickyCount, null, null)
			EmitSoundEx({
				sound_name  = bCrit ? STICKYTANK_SND_SHOOT_CRIT : STICKYTANK_SND_SHOOT
				entity      = self
				filter_type = RECIPIENT_FILTER_GLOBAL
				sound_level = 82
			})
		}

		hStickies <- []
		local flTimeNext = Time() + 7
		function Think()
		{
			foreach(i, hSticky in hStickies)
				if(!(hSticky && hSticky.IsValid()))
					hStickies.remove(i)

			local FindStickies = function(hMimic)
			{
				for(local hSticky; hSticky = FindByClassnameWithin(hSticky, "tf_projectile_pipe", hMimic.GetOrigin(), 32);)
					if(GetPropEntity(hSticky, "m_hThrower") == null && hSticky.GetOwner() == null)
					{
						hSticky.SetTeam(self.GetTeam())
						hSticky.SetOwner(self)
						hStickies.append(hSticky)
					}
			}

			if(hMimic1 && hMimic1.IsValid())
				FindStickies(hMimic1)

			if(hMimic2 && hMimic2.IsValid())
				FindStickies(hMimic2)

			if(flTime >= flTimeNext)
			{
				flTimeNext = flTime + 7
				ShootStickies()
				TankExt.DelayFunction(self, this, 0.1, ShootStickies )
				TankExt.DelayFunction(self, this, 0.2, ShootStickies )
				TankExt.DelayFunction(self, this, 0.3, ShootStickies )
				TankExt.DelayFunction(self, this, 0.4, ShootStickies )
				TankExt.DelayFunction(self, this, 0.5, function() { ShootStickies(4) })
				TankExt.DelayFunction(self, this, 0.6, ShootStickies)
				TankExt.DelayFunction(self, this, 0.7, ShootStickies)
				TankExt.DelayFunction(self, this, 0.8, ShootStickies)
				TankExt.DelayFunction(self, this, 0.9, ShootStickies)
				TankExt.DelayFunction(self, this, 1.0, function() { ShootStickies(4) })
				TankExt.DelayFunction(self, this, 1.5, function() { ShootStickies(1, true) })
				TankExt.DelayFunction(self, this, 2.0, function() { ShootStickies(2, true) })
				TankExt.DelayFunction(self, this, 2.5, function() { ShootStickies(3, true) })
				TankExt.DelayFunction(self, this, 3.0, function() { ShootStickies(6, true) })
				TankExt.DelayFunction(self, this, 7.0, function() {
					hMimic1.AcceptInput("DetonateStickies", null, null, null)
					hMimic2.AcceptInput("DetonateStickies", null, null, null)
				})
			}
		}
	}
	function OnDeath()
	{
		foreach(hSticky in hStickies)
			if(hSticky && hSticky.IsValid())
				hSticky.Kill()
	}
})