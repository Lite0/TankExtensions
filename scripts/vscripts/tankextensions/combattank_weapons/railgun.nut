local COMBATTANK_VALUES_TABLE = {
	COMBATTANK_RAILGUN_SND_CHARGE           = ")misc/doomsday_cap_close_quick.wav"
	COMBATTANK_RAILGUN_SND_FIRE1            = ")weapons/shooting_star_shoot_charged.wav"
	COMBATTANK_RAILGUN_SND_FIRE2            = ")weapons/sniper_railgun_charged_shot_01.wav"
	COMBATTANK_RAILGUN_MODEL                = "models/bots/boss_bot/combat_tank/combat_tank_railgun.mdl"
	COMBATTANK_RAILGUN_MODEL_CASING         = "models/bots/boss_bot/combat_tank/railgun_case.mdl"
	COMBATTANK_MINIGUN_PARTICLE_TRACER_RED  = "dxhr_sniper_rail_red"
	COMBATTANK_MINIGUN_PARTICLE_TRACER_BLUE = "dxhr_sniper_rail_blue"
	COMBATTANK_RAILGUN_FIRE_DELAY           = 8
	COMBATTANK_RAILGUN_BULLET_DAMAGE        = 75 // 225
}
foreach(k,v in COMBATTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(COMBATTANK_RAILGUN_MODEL)
PrecacheModel(COMBATTANK_RAILGUN_MODEL_CASING)
TankExt.PrecacheSound(COMBATTANK_RAILGUN_SND_CHARGE)
TankExt.PrecacheSound(COMBATTANK_RAILGUN_SND_FIRE1)
TankExt.PrecacheSound(COMBATTANK_RAILGUN_SND_FIRE2)

TankExt.CombatTankWeapons["railgun"] <- {
	Model = COMBATTANK_RAILGUN_MODEL
	function OnSpawn()
	{
		local flNextAttack = 0.0
		local bCharging = false

		local hCasingShooter = SpawnEntityFromTable("env_shooter", {
			origin           = Vector(-66, -38, 0)
			angles           = QAngle(0, -90, 0)
			shootmodel       = COMBATTANK_RAILGUN_MODEL_CASING
			m_flGibLife      = 5
			m_flVariance     = 0.15
			m_flVelocity     = 200
			m_iGibs          = 1
			nogibshadows     = 1
			shootsounds      = -1
			spawnflags       = 5
			gibanglevelocity = 10
		})
		TankExt.SetParentArray([hCasingShooter], self)

		function Shoot()
		{
			flNextAttack = Time() + COMBATTANK_RAILGUN_FIRE_DELAY
			bCharging = false
			hTank_scope.AddToSoundQueue({
				sound_name  = COMBATTANK_RAILGUN_SND_FIRE1
				sound_level = 100
				entity      = hTank
				filter_type = RECIPIENT_FILTER_GLOBAL
			})
			hTank_scope.AddToSoundQueue({
				sound_name  = COMBATTANK_RAILGUN_SND_FIRE2
				sound_level = 100
				entity      = hTank
				filter_type = RECIPIENT_FILTER_GLOBAL
			})

			local iTeamNum = hTank.GetTeam()
			local LaserTrace = hTank_scope.LaserTrace
			if("enthit" in LaserTrace)
			{
				local hHit = LaserTrace.enthit
				if("GetTeam" in hHit && hHit.GetTeam() != iTeamNum)
				{
					local sClassname = hHit.GetClassname()
					if(sClassname == "player")
						if(!hHit.InCond(TF_COND_DISGUISED))
							hHit.EmitSound("Flesh.BulletImpact")
					if(startswith(sClassname, "obj_"))
						hHit.EmitSound("SolidMetal.BulletImpact")
					hHit.TakeDamageCustom(hTank, hTank, null, Vector(), Vector(), COMBATTANK_RAILGUN_BULLET_DAMAGE, DMG_BULLET | DMG_ACID, TF_DMG_CUSTOM_HEADSHOT)
				}
			}

			local sEffectName = iTeamNum == TF_TEAM_BLUE ? COMBATTANK_MINIGUN_PARTICLE_TRACER_BLUE : COMBATTANK_MINIGUN_PARTICLE_TRACER_RED
			local SpawnParticleSystem = @(vecOrigin) SpawnEntityFromTable("info_particle_system", {
				origin       = vecOrigin
				effect_name  = sEffectName
				start_active = 1
			})
			local hParticleTracers = [
				SpawnParticleSystem(Vector(0, 1, 1))
				SpawnParticleSystem(Vector(0, -1, 1))
				SpawnParticleSystem(Vector(0, -1, -1))
				SpawnParticleSystem(Vector(0, 1, -1))
			]
			TankExt.SetParentArray(hParticleTracers, self, "barrel")

			local hTracerTarget = SpawnEntityFromTable("info_target", { origin = hTank_scope.LaserTrace.endpos, spawnflags = 0x01 })
			SetPropBool(hTracerTarget, "m_bForcePurgeFixedupStrings", true)
			EntFireByHandle(hTracerTarget, "Kill", null, 0.066, null, null)

			foreach(hParticleTracer in hParticleTracers)
			{
				SetPropBool(hParticleTracer, "m_bForcePurgeFixedupStrings", true)
				SetPropEntityArray(hParticleTracer, "m_hControlPointEnts", hTracerTarget, 0)
				EntFireByHandle(hParticleTracer, "Kill", null, 0.066, null, null)
			}

			EntFireByHandle(hCasingShooter, "Shoot", null, 0.1, null, null)
		}
		function Think()
		{
			if(!(self && self.IsValid())) return
			local LaserTrace = hTank_scope.LaserTrace
			local bInLaser = "enthit" in LaserTrace && LaserTrace.enthit == hTank_scope.hTarget
			if(!bCharging && bInLaser && Time() >= flNextAttack)
			{
				bCharging = true
				hTank_scope.AddToSoundQueue({
					sound_name  = COMBATTANK_RAILGUN_SND_CHARGE
					sound_level = 100
					entity      = hTank
					filter_type = RECIPIENT_FILTER_GLOBAL
				})
				self.AcceptInput("SetAnimation", "fire", null, null)
				EntFireByHandle(self, "CallScriptFunction", "Shoot", 1.7, null, null)
			}
			return -1
		}
		TankExt.AddThinkToEnt(self, "Think")
	}
}
