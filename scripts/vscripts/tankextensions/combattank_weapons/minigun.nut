////////////////////////////////////////////////////////////////////////////////////////////
// includes:
//     minigun
////////////////////////////////////////////////////////////////////////////////////////////
// extra weapons get added to the list by appending to the CombatTankWeapons table
// then the weapon script will need to have an IncludeScript in the main popfile
// CombatTankWeapons.minigun <- {
//     Spawn = function(hTank)
//     {
//     
//     }
//     OnDeath = function()
//     {
//
//     }
////////////////////////////////////////////////////////////////////////////////////////////

local COMBATTANK_VALUES_TABLE = {
	COMBATTANK_MINIGUN_SPREAD_MULTIPLIER = 1
	COMBATTANK_MINIGUN_SND_SPINUP        = "mvm/giant_heavy/giant_heavy_gunwindup.wav"
	COMBATTANK_MINIGUN_SND_SPINNING      = "mvm/giant_heavy/giant_heavy_gunspin.wav"
	COMBATTANK_MINIGUN_SND_SPINDOWN      = "mvm/giant_heavy/giant_heavy_gunwinddown.wav"
	COMBATTANK_MINIGUN_SND_FIRE          = "mvm/giant_heavy/giant_heavy_gunfire.wav"
	COMBATTANK_MINIGUN_PARTICLE_TRACER   = "bullet_tracer01"
	COMBATTANK_MINIGUN_PARTICLE_MUZZLE   = "muzzle_minigun_constant"
	COMBATTANK_MINIGUN_PARTICLE_CASING   = "eject_minigunbrass"
	COMBATTANK_MINIGUN_MODEL             = "models/bots/boss_bot/combat_tank/combat_tank_minigun.mdl"
	COMBATTANK_MINIGUN_FIRE_DELAY        = 0.066
	COMBATTANK_MINIGUN_CONE_RADIUS       = 25
	COMBATTANK_MINIGUN_BULLET_DAMAGE     = 22
}
foreach(k,v in COMBATTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheSound(COMBATTANK_MINIGUN_SND_SPINUP)
PrecacheSound(COMBATTANK_MINIGUN_SND_SPINNING)
PrecacheSound(COMBATTANK_MINIGUN_SND_FIRE)
PrecacheSound(COMBATTANK_MINIGUN_SND_SPINDOWN)

CombatTankWeapons.minigun <- {
	Spawn = function(hTank)
	{
		local hMinigun = SpawnEntityFromTable("prop_dynamic", { model = COMBATTANK_MINIGUN_MODEL, defaultanim = "idle" })
		hMinigun.ValidateScriptScope()
		local hMinigun_scope = hMinigun.GetScriptScope()
		hMinigun_scope.hTank <- hTank
		hMinigun_scope.hTank_scope <- hTank.GetScriptScope()
		hMinigun_scope.hParticleMuzzle1 <- SpawnEntityFromTable("info_particle_system", { effect_name = COMBATTANK_MINIGUN_PARTICLE_MUZZLE })
		hMinigun_scope.hParticleMuzzle2 <- SpawnEntityFromTable("info_particle_system", { effect_name = COMBATTANK_MINIGUN_PARTICLE_MUZZLE })
		hMinigun_scope.hParticleCasing1 <- SpawnEntityFromTable("info_particle_system", { effect_name = COMBATTANK_MINIGUN_PARTICLE_CASING })
		hMinigun_scope.hParticleCasing2 <- SpawnEntityFromTable("info_particle_system", { effect_name = COMBATTANK_MINIGUN_PARTICLE_CASING })
		TankExt.SetParentArray([hMinigun_scope.hParticleMuzzle1], hMinigun, "barrel_1")
		TankExt.SetParentArray([hMinigun_scope.hParticleMuzzle2], hMinigun, "barrel_2")
		TankExt.SetParentArray([hMinigun_scope.hParticleCasing1], hMinigun, "case_eject_1")
		TankExt.SetParentArray([hMinigun_scope.hParticleCasing2], hMinigun, "case_eject_2")
		hMinigun_scope.flNextAttack <- 0.0
		hMinigun_scope.flTimeIdle <- 0.0
		hMinigun_scope.iState <- 0
		hMinigun_scope.iBarrel <- 0

		hMinigun_scope.Think <- function()
		{
			if(!(self && self.IsValid())) return
			local flTime = Time()
			if(hTank_scope.hEnemy)
			{
				if(iState == 0)
				{
					iState = 1
					TankExt.CombatTankPlaySound({
						sound_name = COMBATTANK_MINIGUN_SND_SPINUP
						sound_level = 90
						entity = hTank
						filter_type = RECIPIENT_FILTER_GLOBAL
					})
					EntFireByHandle(self, "SetAnimation", "spin_up", -1, null, null)
					flTimeIdle = flTime + 1
				}
				if(flTime >= flTimeIdle || iState > 1)
				{
					local bEnemyInCone = hTank_scope.flAngleDist != null && hTank_scope.flAngleDist < COMBATTANK_MINIGUN_CONE_RADIUS
					if(iState == 1) EntFireByHandle(self, "SetAnimation", "spining", -1, null, null)
					if(!bEnemyInCone && iState != 2)
					{
						iState = 2
						self.SetBodygroup(1, 0)
						TankExt.CombatTankPlaySound({
							sound_name = COMBATTANK_MINIGUN_SND_SPINNING
							sound_level = 90
							entity = hTank
							filter_type = RECIPIENT_FILTER_GLOBAL
						}, true)
						EntFireByHandle(hParticleMuzzle1, "Stop", null, -1, null, null)
						EntFireByHandle(hParticleMuzzle2, "Stop", null, -1, null, null)
						EntFireByHandle(hParticleCasing1, "Stop", null, -1, null, null)
						EntFireByHandle(hParticleCasing2, "Stop", null, -1, null, null)
					}
					if(bEnemyInCone)
					{
						if(iState != 3)
						{
							iState = 3
							self.SetBodygroup(1, 1)
							TankExt.CombatTankPlaySound({
								sound_name = COMBATTANK_MINIGUN_SND_FIRE
								sound_level = 90
								entity = hTank
								filter_type = RECIPIENT_FILTER_GLOBAL
							}, true)
						}
	
						if(flTime >= flNextAttack)
						{
							flNextAttack = flTime + COMBATTANK_MINIGUN_FIRE_DELAY
							iBarrel = iBarrel ? 0 : 1
							local vecTowardsEnemy = RotatePosition(Vector(), QAngle(RandomFloat(-5, 5), RandomFloat(-5, 5)) * COMBATTANK_MINIGUN_SPREAD_MULTIPLIER, hTank_scope.vecEnemyTarget - hTank_scope.vecMount)
							vecTowardsEnemy.Norm()
	
							local Trace = {
								start = hTank_scope.vecMount
								end = hTank_scope.vecMount + vecTowardsEnemy * 8192
								ignore = hTank
								mask = MASK_SHOT
							}
							TraceLineEx(Trace)
							if("enthit" in Trace && Trace.enthit.IsPlayer() && Trace.enthit.GetTeam() != hTank.GetTeam())
							{
								if(!Trace.enthit.InCond(TF_COND_DISGUISED))
									Trace.enthit.EmitSound("Flesh.BulletImpact")
								Trace.enthit.TakeDamageCustom(hTank, hTank, null, Vector(), Vector(), COMBATTANK_MINIGUN_BULLET_DAMAGE, DMG_BULLET, TF_DMG_CUSTOM_MINIGUN)
							}
	
							local hParticleTracer = SpawnEntityFromTable("info_particle_system", {
								effect_name = COMBATTANK_MINIGUN_PARTICLE_TRACER
								start_active = 1
							})
							SetPropBool(hParticleTracer, "m_bForcePurgeFixedupStrings", true)
							TankExt.SetParentArray([hParticleTracer], self, iBarrel ? "barrel_1" : "barrel_2")
							local hTracerTarget = SpawnEntityFromTable("info_target", { origin = Trace.endpos, spawnflags = 0x01 })
							SetPropBool(hTracerTarget, "m_bForcePurgeFixedupStrings", true)
							SetPropEntityArray(hParticleTracer, "m_hControlPointEnts", hTracerTarget, 0)
							EntFireByHandle(hParticleTracer, "Kill", null, COMBATTANK_MINIGUN_FIRE_DELAY, null, null)
							EntFireByHandle(hTracerTarget, "Kill", null, COMBATTANK_MINIGUN_FIRE_DELAY, null, null)
							EntFireByHandle(hParticleMuzzle1, "Start", null, -1, null, null)
							EntFireByHandle(hParticleMuzzle2, "Start", null, -1, null, null)
							EntFireByHandle(hParticleCasing1, "Start", null, -1, null, null)
							EntFireByHandle(hParticleCasing2, "Start", null, -1, null, null)
						}
					}
					flTimeIdle = flTime + 1
				}
			}
			else if(flTime <= flTimeIdle)
			{
				if(iState > 2)
				{
					iState = 2
					TankExt.CombatTankPlaySound({
						sound_name = COMBATTANK_MINIGUN_SND_SPINNING
						sound_level = 90
						entity = hTank
						filter_type = RECIPIENT_FILTER_GLOBAL
					}, true)
					EntFireByHandle(hParticleMuzzle1, "Stop", null, -1, null, null)
					EntFireByHandle(hParticleMuzzle2, "Stop", null, -1, null, null)
					EntFireByHandle(hParticleCasing1, "Stop", null, -1, null, null)
					EntFireByHandle(hParticleCasing2, "Stop", null, -1, null, null)
				}
			}
			else if(iState != 0)
			{
				iState = 0
				TankExt.CombatTankPlaySound({
					sound_name = COMBATTANK_MINIGUN_SND_SPINDOWN
					sound_level = 90
					entity = hTank
					filter_type = RECIPIENT_FILTER_GLOBAL
				})
				EntFireByHandle(self, "SetAnimation", "spin_down", -1, null, null)
			}
			
			iState != 0 ? TankExt.CombatTankStopSound({
				sound_name = COMBATTANK_MINIGUN_SND_SPINDOWN
				entity = hTank
				filter_type = RECIPIENT_FILTER_GLOBAL
				flags = SND_STOP
			}) : null
			iState != 1 ? TankExt.CombatTankStopSound({
				sound_name = COMBATTANK_MINIGUN_SND_SPINUP
				entity = hTank
				filter_type = RECIPIENT_FILTER_GLOBAL
				flags = SND_STOP
			}) : null
			iState != 2 ? TankExt.CombatTankStopSound({
				sound_name = COMBATTANK_MINIGUN_SND_SPINNING
				entity = hTank
				filter_type = RECIPIENT_FILTER_GLOBAL
				flags = SND_STOP
			}) : null
			iState != 3 ? TankExt.CombatTankStopSound({
				sound_name = COMBATTANK_MINIGUN_SND_FIRE
				entity = hTank
				filter_type = RECIPIENT_FILTER_GLOBAL
				flags = SND_STOP
			}) : null
			return -1
		}
		TankExt.AddThinkToEnt(hMinigun, "Think")
		return hMinigun
	}
}
