local STICKYTANK_VALUES_TABLE = {
	STICKYTANK_TURRET_MODEL             = "models/props_frontline/tank_turret.mdl"
	STICKYTANK_SND_SHOOT_CRIT           = "weapons/stickybomblauncher_shoot_crit.wav"
	STICKYTANK_SND_SHOOT                = "weapons/stickybomblauncher_shoot.wav"
	STICKYTANK_PROJECTILE_MODEL         = "models/weapons/w_models/w_stickybomb.mdl"
	STICKYTANK_PROJECTILE_SPREAD        = 25
	STICKYTANK_PROJECTILE_SPLASH_RADIUS = 189
	STICKYTANK_PROJECTILE_SPEED         = 525
	STICKYTANK_PROJECTILE_DAMAGE        = 105
}
foreach(k,v in STICKYTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(STICKYTANK_PROJECTILE_MODEL)
PrecacheSound(STICKYTANK_SND_SHOOT)
PrecacheSound(STICKYTANK_SND_SHOOT_CRIT)

TankExt.NewTankScript("stickytank", {
	OnSpawn = function(hTank, sName, hPath)
	{
		local hTank_scope = hTank.GetScriptScope()
		local hModel1 = SpawnEntityFromTable("prop_dynamic", { origin = "-16 -66 108", angles = "-58.5 0 -90", model = STICKYTANK_TURRET_MODEL, skin = 2 })
		local hModel2 = SpawnEntityFromTable("prop_dynamic", { origin = "-16 66 108", angles = "-58.5 0 90", model = STICKYTANK_TURRET_MODEL, skin = 2 })
		hTank_scope.hMimic1 <- SpawnEntityFromTable("tf_point_weapon_mimic", { origin = "51 57 217", angles = "-58.5 0 0", damage = STICKYTANK_PROJECTILE_DAMAGE, modelscale = 1, modeloverride = STICKYTANK_PROJECTILE_MODEL, speedmax = STICKYTANK_PROJECTILE_SPEED, speedmin = STICKYTANK_PROJECTILE_SPEED, splashradius = STICKYTANK_PROJECTILE_SPLASH_RADIUS, weapontype = 3, spreadangle = STICKYTANK_PROJECTILE_SPREAD })
		hTank_scope.hMimic2 <- SpawnEntityFromTable("tf_point_weapon_mimic", { origin = "51 -57 217", angles = "-58.5 0 0", damage = STICKYTANK_PROJECTILE_DAMAGE, modelscale = 1, modeloverride = STICKYTANK_PROJECTILE_MODEL, speedmax = STICKYTANK_PROJECTILE_SPEED, speedmin = STICKYTANK_PROJECTILE_SPEED, splashradius = STICKYTANK_PROJECTILE_SPLASH_RADIUS, weapontype = 3, spreadangle = STICKYTANK_PROJECTILE_SPREAD })
		TankExt.SetParentArray([hTank_scope.hMimic1, hTank_scope.hMimic2, hModel1, hModel2], hTank)

		hTank_scope.ShootStickies <- function(iStickyCount = 1, bCrit = false)
		{
			local sMultiple = iStickyCount <= 1 ? "FireMultiple" : "FireOnce"
			local sStickyCount = iStickyCount.tostring()
			SetPropBool(hMimic1, "m_bCrits", bCrit)
			SetPropBool(hMimic2, "m_bCrits", bCrit)
			EntFireByHandle(hMimic1, sMultiple, sStickyCount, -1, null, null)
			EntFireByHandle(hMimic2, sMultiple, sStickyCount, -1, null, null)
			EmitSoundEx({
				sound_name = bCrit ? STICKYTANK_SND_SHOOT_CRIT : STICKYTANK_SND_SHOOT
				entity = self
				filter_type = RECIPIENT_FILTER_GLOBAL
				sound_level = 82
			})
		}
		hTank_scope.flTimeNext <- Time()
		hTank_scope.Think <- function()
		{
			if(hMimic1 && hMimic2 && hMimic1.IsValid() && hMimic2.IsValid())
			{
				local iTeamNum = self.GetTeam()
				local StickyCheck = function(hSticky)
				{
					if(GetPropEntity(hSticky, "m_hThrower") != null && hSticky.GetScriptScope() == null) return
					SetPropBool(hSticky, "m_bForcePurgeFixedupStrings", true)
					hSticky.ValidateScriptScope()
					hSticky.GetScriptScope().hTank <- self
				}

				for(local hSticky; hSticky = FindByClassnameWithin(hSticky, "tf_projectile_pipe", hMimic1.GetOrigin(), 32);)
					StickyCheck(hSticky)
				for(local hSticky; hSticky = FindByClassnameWithin(hSticky, "tf_projectile_pipe", hMimic2.GetOrigin(), 32);)
					StickyCheck(hSticky)
			}
			else 
				return
			
			if(Time() >= flTimeNext)
			{
				flTimeNext += 7
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", -1, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.1, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.2, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.3, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.4, null, null)
				EntFireByHandle(self, "RunScriptCode", "ShootStickies(4)", 0.5, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.6, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.7, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.8, null, null)
				EntFireByHandle(self, "CallScriptFunction", "ShootStickies", 0.9, null, null)
				EntFireByHandle(self, "RunScriptCode", "ShootStickies(4)", 1, null, null)
				EntFireByHandle(self, "RunScriptCode", "ShootStickies(1, true)", 1.5, null, null)
				EntFireByHandle(self, "RunScriptCode", "ShootStickies(2, true)", 2, null, null)
				EntFireByHandle(self, "RunScriptCode", "ShootStickies(3, true)", 2.5, null, null)
				EntFireByHandle(self, "RunScriptCode", "ShootStickies(6, true)", 3, null, null)
				EntFireByHandle(hMimic1, "DetonateStickies", null, 7, null, null)
				EntFireByHandle(hMimic2, "DetonateStickies", null, 7, null, null)
			}
			return -1
		}
		TankExt.AddThinkToEnt(hTank, "Think")
	}
	OnDeath = function()
	{
		for(local hSticky; hSticky = FindByClassname(hSticky, "tf_projectile_pipe");)
		{
			local hSticky_scope = hSticky.GetScriptScope()
			if("hTank" in hSticky_scope && !hSticky_scope.hTank.IsValid())
				hSticky.Destroy()
		}
	}
})