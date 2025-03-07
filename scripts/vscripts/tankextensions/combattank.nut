////////////////////////////////////////////////////////////////////////////////////////////
// example tank name : "combattank|rocketpod|minigun"
// add _red to combattank for a red teamed tank
// second argument, rocketpod, places it on the tank's left side
// third argument, minigun, places it on the tank's right side
// intended to be put onto a LOOPING path
////////////////////////////////////////////////////////////////////////////////////////////
// look at scripts inside of the combattank_weapons folder for weapon names
////////////////////////////////////////////////////////////////////////////////////////////
// popfile example can be found at https://testing.potato.tf/tf/scripts/population/mvm_slick_v4_combattank.pop
////////////////////////////////////////////////////////////////////////////////////////////

local COMBATTANK_VALUES_TABLE = {
	COMBATTANK_SND_ROTATE           = ")plats/tram_move.wav"
	COMBATTANK_SND_UBER             = "player/invulnerable_on.wav"
	COMBATTANK_SND_UBER_OFF         = "player/invulnerable_off.wav"
	COMBATTANK_ROTATE_SPEED_DEFAULT = 0.8
	COMBATTANK_POSE_YAW             = 2
	COMBATTANK_POSE_PITCH           = 1
	COMBATTANK_MODEL                = "models/bots/boss_bot/combat_tank/combat_tank.mdl"
	COMBATTANK_TRACK_L_BLUE         = "models/bots/boss_bot/tank_track_l.mdl"
	COMBATTANK_TRACK_R_BLUE         = "models/bots/boss_bot/tank_track_r.mdl"
	COMBATTANK_TRACK_L_RED          = "models/bots/boss_bot/tankred_track_l.mdl"
	COMBATTANK_TRACK_R_RED          = "models/bots/boss_bot/tankred_track_r.mdl"
	COMBATTANK_MAX_RANGE            = 1400
}
foreach(k,v in COMBATTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(COMBATTANK_MODEL)
PrecacheModel(COMBATTANK_TRACK_L_BLUE)
PrecacheModel(COMBATTANK_TRACK_R_BLUE)
PrecacheModel(COMBATTANK_TRACK_L_RED)
PrecacheModel(COMBATTANK_TRACK_R_RED)
TankExt.PrecacheSound(COMBATTANK_SND_ROTATE)
TankExt.PrecacheSound(COMBATTANK_SND_UBER)
TankExt.PrecacheSound(COMBATTANK_SND_UBER_OFF)

::UberTankEvents <- {
	function OnGameEvent_recalculate_holidays(_) { if(GetRoundState() == 3) delete ::UberTankEvents }
	function OnScriptHook_OnTakeDamage(params)
	{
		local hAttacker = params.attacker
		local hVictim   = params.const_entity
		if(hAttacker && hVictim && hVictim.GetClassname() == "tank_boss" && hAttacker.GetTeam() != hVictim.GetTeam())
		{
			local CombatScope = TankExt.GetMultiScopeTable(hVictim.GetScriptScope(), "combattank")
			if(CombatScope && CombatScope.bUbered)
			{
				params.damage = 0
				EmitSoundOn("FX_RicochetSound.Ricochet", hVictim)
			}
		}
	}
}
__CollectGameEventCallbacks(UberTankEvents)

TankExt.CombatTankWeapons <- {}

TankExt.NewTankType("combattank*", {
	Model       = COMBATTANK_MODEL
	DisableBomb = 1
	function OnSpawn()
	{
		local SoundQueue = {}
		function AddToSoundQueue(Table)
		{
			local TableStop = clone Table
			TableStop.flags <- SND_STOP
			EmitSoundEx(TableStop)
			SoundQueue[Table.sound_name] <- Table
		}

		local angCurrent    = QAngle()
		local angGoalIdle   = QAngle()
		local angGoal       = QAngle()
		local hTargetLast   = null
		local flRotateSpeed = COMBATTANK_ROTATE_SPEED_DEFAULT
		local iLaser        = self.LookupAttachment("laser_origin")
		vecMount       <- null
		vecTarget <- null
		hTarget        <- null
		flAngleDist    <- -1

		LaserTrace <- {}

		EmitSoundEx({
			sound_name  = COMBATTANK_SND_ROTATE
			sound_level = 85
			entity      = self
			filter_type = RECIPIENT_FILTER_GLOBAL
			pitch       = 90
		})

		local sParams = split(sTankName, "|")
		local iParamsLength = sParams.len()
		if(iParamsLength < 2) sParams.append("minigun")
		if(iParamsLength < 3) sParams.append(sParams[1])

		if(sParams[0].find("_red")) self.SetTeam(TF_TEAM_RED) // legacy, can append $teamnum|2 to the tank name instead

		hBeam    <- null
		hBeamEnd <- null
		local bBlueTeam  = self.GetTeam() == TF_TEAM_BLUE
		local bFinalSkin = self.GetSkin() == 1
		if(sParams[0].find("_nolaser") == null)
		{
			hBeam = SpawnEntityFromTable("env_beam", { lightningstart = "bignet", lightningend = "bignet", boltwidth = 0.75, texture = "sprites/laserbeam.vmt", rendercolor = bBlueTeam ? "20 70 120" : "135 10 10" })
			SetPropBool(hBeam, "m_bForcePurgeFixedupStrings", true)
			hBeamEnd = SpawnEntityFromTable("env_sprite", { model = "sprites/glow1.vmt", rendermode = 5, rendercolor = bBlueTeam ? "20 70 120" : "135 10 10" })
			SetPropBool(hBeamEnd, "m_bForcePurgeFixedupStrings", true)
			SetPropEntityArray(hBeam, "m_hAttachEntity", hBeam, 0)
			SetPropEntityArray(hBeam, "m_hAttachEntity", hBeamEnd, 1)
		}

		self.SetSkin(bBlueTeam ? bFinalSkin ? 3 : 2 : bFinalSkin ? 1 : 0)
		for(local i = 1; i <= 2; i++)
			if(sParams[i] in TankExt.CombatTankWeapons)
			{
				local WeaponTable = TankExt.CombatTankWeapons[sParams[i]]
				local hWeapon
				if("Model" in WeaponTable)
				{
					hWeapon = TankExt.SpawnEntityFromTableFast("prop_dynamic", { model = WeaponTable.Model, defaultanim = ("DefaultAnim" in WeaponTable) ? WeaponTable.DefaultAnim : "" })
					hWeapon.SetSkin(bBlueTeam ? 1 : 0)
					TankExt.SetParentArray([hWeapon], self, i == 1 ? "weapon_r" : "weapon_l")
				}
				if("OnSpawn" in WeaponTable)
				{
					hWeapon.ValidateScriptScope()
					local hWeapon_scope = hWeapon.GetScriptScope()
					hWeapon_scope.hTank <- self
					hWeapon_scope.hTank_scope <- this
					WeaponTable.OnSpawn.call(hWeapon_scope)
				}
				if("OnDeath" in WeaponTable)
					TankExt.SetDestroyCallback(hWeapon, WeaponTable.OnDeath)
			}
			else ClientPrint(null, HUD_PRINTTALK, format("\x07FFFF00CombatTank weapon \"%s\" does not exist, weapon is not loaded or does not exist", sParams[i]))

		local LastSkins   = {}
		local bUberFizzle = false
		bUbered <- false
		function ToggleUber()
		{
			if(!bUberFizzle)
				if(!bUbered)
				{
					bUbered = true
					EmitSoundEx({
						sound_name  = COMBATTANK_SND_UBER
						filter_type = RECIPIENT_FILTER_GLOBAL
					})
					SetPropInt(self, "m_takedamage", DAMAGE_NO)
					LastSkins.clear()
					LastSkins[self] <- self.GetSkin()
					self.SetSkin(bBlueTeam ? 5 : 4)
					for(local hChild = self.FirstMoveChild(); hChild; hChild = hChild.NextMovePeer())
						if(hChild.GetModelName().tolower().find("/combat_tank/"))
						{
							LastSkins[hChild] <- hChild.GetSkin()
							hChild.SetSkin(bBlueTeam ? 3 : 2)
						}
				}
				else
				{
					bUberFizzle = true
					EmitSoundEx({
						sound_name  = COMBATTANK_SND_UBER_OFF
						filter_type = RECIPIENT_FILTER_GLOBAL
					})
					TankExt.DelayFunction(self, this, 1, function()
					{
						bUbered     = false
						bUberFizzle = false
						SetPropInt(self, "m_takedamage", DAMAGE_NO)
						foreach(hEnt, iSkin in LastSkins)
							if(hEnt.IsValid())
							{
								hEnt.SetSkin(iSkin)
								hEnt.AcceptInput("Color", "255 255 255", null, null)
							}
					})
				}
		}
		local CombatScope = this
		self.GetScriptScope().ToggleUber <- @() CombatScope.ToggleUber()

		function Think()
		{
			foreach(sSound, Table in SoundQueue)
				EmitSoundEx(Table)
			SoundQueue.clear()

			if(bUberFizzle)
			{
				local flColor = 127.5 - sin(flTime * 20.95) * 127.5 // 20.95 == PI / 0.3 * 0.5
				local sColor  = format("%i %i %i", flColor, flColor, flColor)
				foreach(hEnt, iSkin in LastSkins) if(hEnt.IsValid()) hEnt.AcceptInput("Color", sColor, null, null)
			}

			vecMount       = self.GetAttachmentOrigin(self.LookupAttachment("weapon_l"))
			hTarget        = null
			vecTarget = null
			foreach(sClassname in [ "player", "obj_sentrygun", "obj_dispenser", "obj_teleporter", "tank_boss", "merasmus", "headless_hatman", "eyeball_boss", "tf_zombie" ])
			{
				for(local hEnt, flDist = COMBATTANK_MAX_RANGE; hEnt = FindByClassnameWithin(hEnt, sClassname, vecOrigin, flDist);)
				{
					local vecEntCenter = hEnt.GetCenter()
					local bHasEyes     = "EyePosition" in hEnt
					local vecEntEye    = bHasEyes ? hEnt.EyePosition() : vecEntCenter
					local bCenterTrace = TraceLine(vecEntCenter, vecMount, self) == 1
					local bEyeTrace    = bCenterTrace
					if(bHasEyes) bEyeTrace = TraceLine(vecEntEye, vecMount, self) == 1
					if
					(
						bEyeTrace &&
						hEnt.IsAlive() &&
						hEnt.GetTeam() != iTeamNum &&
						!(hEnt.GetFlags() & FL_NOTARGET) &&
						!TankExt.IsPlayerStealthedOrDisguised(hEnt)
					)
					{
						hTarget = hEnt
						vecTarget = bCenterTrace ? vecEntCenter : vecEntEye
						flDist = (vecEntCenter - vecMount).Length()
					}
				}
				if(hTarget) break
			}

			if(hTarget != hTargetLast)
			{
				hTargetLast = hTarget
				if(hTarget)
				{
					local Sound = @(hEnt, sSound, iFlags) EmitSoundEx({
						sound_name  = sSound
						volume      = hEnt == self ? 1.0 : 0.5
						sound_level = 88
						flags       = iFlags
						pitch       = 95
						entity      = hEnt
						filter_type = hEnt == self ? RECIPIENT_FILTER_GLOBAL : RECIPIENT_FILTER_SINGLE_PLAYER
					})
					Sound(self, "weapons/sentry_spot.wav", SND_STOP)
					Sound(self, "weapons/sentry_spot.wav", SND_NOFLAGS)
					Sound(hTarget, "weapons/sentry_spot_client.wav", SND_STOP)
					Sound(hTarget, "weapons/sentry_spot_client.wav", SND_NOFLAGS)
				}
			}

			local vecLaser = self.GetAttachmentOrigin(iLaser)
			local angLaser = self.GetAttachmentAngles(iLaser)
			LaserTrace = {
				start  = vecLaser
				end    = vecLaser + angLaser.Forward() * 8192
				ignore = self
				mask   = MASK_SHOT_HULL
			}
			TraceLineEx(LaserTrace)

			local bBeam    = hBeam && hBeam.IsValid()
			local bBeamEnd = hBeamEnd && hBeamEnd.IsValid()
			if(hTarget)
			{
				flRotateSpeed = COMBATTANK_ROTATE_SPEED_DEFAULT
				local angToTarget = TankExt.VectorAngles(RotatePosition(Vector(), angRotation * -1, vecTarget - vecMount))

				angToTarget.y = 360.0 - angToTarget.y
				angToTarget.x = -TankExt.Clamp(angToTarget.x - (angToTarget.x > 180 ? 360 : 0), -14, 14)
				angGoal = angToTarget
				if("enthit" in LaserTrace && LaserTrace.enthit == hTarget)
				{
					LaserTrace.end = vecTarget
					TraceLineEx(LaserTrace)
				}
				if(bBeam)
				{
					hBeam.SetAbsOrigin(vecLaser)
					hBeam.AcceptInput("TurnOn", null, null, null)
				}
				if(bBeamEnd)
				{
					hBeamEnd.SetAbsOrigin(LaserTrace.endpos)
					hBeamEnd.AcceptInput("ShowSprite", null, null, null)
				}
			}
			else
			{
				if(bBeam) hBeam.AcceptInput("TurnOff", null, null, null)
				if(bBeamEnd) hBeamEnd.AcceptInput("HideSprite", null, null, null)
				if(angCurrent.x == angGoal.x && angCurrent.y == angGoal.y)
				{
					flRotateSpeed = COMBATTANK_ROTATE_SPEED_DEFAULT * 0.5
					angGoal.x = RandomFloat(-10, 10)
					angGoal.y = angGoal.y < 180 ? 315 : 45
				}
			}


			////////// RotateMount //////////

			if(angCurrent.x != angGoal.x)
			{
				local iDir = angCurrent.x < angGoal.x ? 1 : -1
				angCurrent.x += flRotateSpeed * iDir * 0.5

				if(iDir == 1 ? angCurrent.x > angGoal.x : angCurrent.x < angGoal.x)
					angCurrent.x = angGoal.x
			}
			self.SetPoseParameter(COMBATTANK_POSE_PITCH, angCurrent.x)

			if(angCurrent.y != angGoal.y)
			{
				local iDir = angCurrent.y < angGoal.y ? 1 : -1
				local bReversed = false
				if(fabs(angGoal.y - angCurrent.y) > 180)
				{
					iDir = -iDir
					bReversed = true
				}

				angCurrent.y += flRotateSpeed * iDir

				if(iDir == 1 ? bReversed ? angCurrent.y < angGoal.y : angCurrent.y > angGoal.y : bReversed ? angCurrent.y > angGoal.y : angCurrent.y < angGoal.y)
					angCurrent.y = angGoal.y

				if(angCurrent.y < 0)
					angCurrent.y += 360
				else if(angCurrent.y >= 360)
					angCurrent.y -= 360
			}
			self.SetPoseParameter(COMBATTANK_POSE_YAW, angCurrent.y)

			flAngleDist = (hTarget ? angCurrent.Forward().Dot(angGoal.Forward()) : -1)
		}
	}
	function OnDeath()
	{
		EmitSoundEx({
			sound_name  = "misc/null.wav"
			entity      = self
			filter_type = RECIPIENT_FILTER_GLOBAL
			flags       = SND_STOP | SND_IGNORE_NAME
		})
		if(hBeam && hBeam.IsValid()) hBeam.Kill()
		if(hBeamEnd && hBeamEnd.IsValid()) hBeamEnd.Kill()
	}
})