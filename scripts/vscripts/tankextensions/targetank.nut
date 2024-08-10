local TARGETANK_VALUES_TABLE = {
	TARGETANK_MODEL_COLOR        = "models/bots/boss_bot/paintable_tank/boss_tank"
	TARGETANK_MODEL_COLOR_TRACKS = "models/bots/boss_bot/paintable_tank/tank_track"
	TARGETANK_MODEL_COLOR_BOMB   = "models/bots/boss_bot/paintable_tank/bomb_mechanism.mdl"
	TARGETANK_MODEL_TARGE        = "models/weapons/c_models/c_targe/c_targe.mdl"
	TARGETANK_IMPACT_DAMAGE      = 75
	TARGETANK_RECHARGE_DURATION  = 10
	TARGETANK_CHARGE_DURATION    = 3
	TARGETANK_CHARGE_SPEED       = 300
	TARGETANK_SND_WARNING        = ")ambient/alarms/klaxon1.wav"
	TARGETANK_SND_CHARGE         = "DemoCharge.Charging"
	TARGETANK_SND_HIT            = ")weapons/demo_charge_hit_flesh2.wav"
	TARGETANK_COLOR1             = "255 0 0"
	TARGETANK_COLOR2             = "255 127 0"
}
foreach(k,v in TARGETANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(TARGETANK_MODEL_COLOR)
PrecacheModel(TARGETANK_MODEL_COLOR_TRACKS)
PrecacheModel(TARGETANK_MODEL_COLOR_BOMB)
PrecacheModel(TARGETANK_MODEL_TARGE)
PrecacheSound(TARGETANK_SND_WARNING)
PrecacheSound(TARGETANK_SND_CHARGE)
PrecacheSound(TARGETANK_SND_HIT)

TankExt.NewTankScript("targetank", {
	OnSpawn = function(hTank, sName, hPath)
	{
		local hTank_scope = hTank.GetScriptScope()
		hTank_scope.hTargeModel <- SpawnEntityFromTable("prop_dynamic", {
			model      = TARGETANK_MODEL_TARGE
			origin     = "90 28 84"
			angles     = "-29.3 194.9 76.8"
			modelscale = 2.5
			skin       = 1
		})
		hTank_scope.hTrail <- SpawnEntityFromTable("env_spritetrail", {
			origin     = "-72 0 96"
			spritename = hTank.GetTeam() == 3 ? "effects/beam001_blu.vmt" : "effects/beam001_red.vmt"
			startwidth = 128
			endwidth   = 1
			lifetime   = 1
		})
		hTank_scope.hTrail.AcceptInput("HideSprite", null, null, null)
		TankExt.SetParentArray([hTank_scope.hTargeModel, hTank_scope.hTrail], hTank)

		if("Paintable" in hTank_scope)
		{
			local Colors1 = split(TARGETANK_COLOR1, " ")
			local Colors2 = split(TARGETANK_COLOR2, " ")
			Colors1.apply(@(value) value.tointeger())
			Colors2.apply(@(value) value.tointeger())
			local vecColor1 = Vector(Colors1[0], Colors1[1], Colors1[2])
			local vecColor2 = Vector(Colors2[0], Colors2[1], Colors2[2])
			hTank_scope.Colors <- [vecColor1, vecColor2]
		}

		hTank_scope.PlayersLast <- []
		hTank_scope.flRechargeDuration <- TARGETANK_RECHARGE_DURATION
		hTank_scope.flChargeDuration <- TARGETANK_CHARGE_DURATION
		hTank_scope.flTimeNext <- Time() + hTank_scope.flRechargeDuration
		hTank_scope.flTimeLast <- Time()
		hTank_scope.flSpeedLast <- 0.0
		hTank_scope.iState <- 0
		hTank_scope.Think <- function()
		{
			local sModel = self.GetModelName()
			local bPaintable = "Paintable" in this
			if(bPaintable && sModel.find(TARGETANK_MODEL_COLOR) == null)
			{
				local sNewModel = TARGETANK_MODEL_COLOR
				if(sModel.find("damage1"))
					sNewModel += "_damage1"
				else if(sModel.find("damage2"))
					sNewModel += "_damage2"
				else if(sModel.find("damage3"))
					sNewModel += "_damage3"
				sNewModel += ".mdl"
				TankExt.SetTankModel(self, sNewModel, TARGETANK_MODEL_COLOR_TRACKS, TARGETANK_MODEL_COLOR_BOMB)
			}

			local flTime = Time()
			local bCanDoAction = flTime >= flTimeNext
			if(iState == 0 && bCanDoAction)
			{
				flTimeNext = flTime + 2
				iState = 1
				flSpeedLast = GetPropFloat(self, "m_speed")
				self.AcceptInput("SetSpeed", "15", null, null)
				local sSound = @"EmitSoundEx({
					sound_name  = TARGETANK_SND_WARNING
					sound_level = 85
					filter_type = RECIPIENT_FILTER_GLOBAL
					entity      = self
				})"

				self.AcceptInput("RunScriptCode", sSound, null, null)
				self.AcceptInput("RunScriptCode", sSound, null, null)
				EntFireByHandle(self, "RunScriptCode", sSound, 1, null, null)
				EntFireByHandle(self, "RunScriptCode", sSound, 1, null, null)
			}
			else if(iState == 1 && bCanDoAction)
			{
				flTimeNext = flTime + flChargeDuration
				flTimeLast = flTime
				iState = 2
				EmitSoundEx({
					sound_name  = TARGETANK_SND_CHARGE
					sound_level = 80
					filter_type = RECIPIENT_FILTER_GLOBAL
					entity      = self
				})
				self.AcceptInput("SetSpeed", TARGETANK_CHARGE_SPEED.tostring(), null, null)
				hTrail.AcceptInput("ShowSprite", null, null, null)
				PlayersLast.clear()
			}
			else if(iState == 2 && bCanDoAction)
			{
				flTimeNext = flTime + flRechargeDuration
				flTimeLast = flTime
				iState = 0
				self.AcceptInput("SetSpeed", flSpeedLast.tostring(), null, null)
				EntFireByHandle(hTrail, "HideSprite", "HideSprite", 1, null, null)
			}

			local flTimePercentage = (flTime - flTimeLast) / (flTimeNext - flTimeLast)
			local Color = function(bool)
			{
				local vecColorCombined = Colors[0] * (bool ? 1 - flTimePercentage : flTimePercentage) + Colors[1] * (bool ? flTimePercentage : 1 - flTimePercentage)
				local sColor = format("%i %i %i", vecColorCombined.x, vecColorCombined.y, vecColorCombined.z)
				self.AcceptInput("Color", sColor, null, null)
				for(local hChild = hTank.FirstMoveChild(); hChild != null; hChild = hChild.NextMovePeer())
				{
					local sChildModel = hChild.GetModelName().tolower()
					if(sChildModel.find("track_"))
						hChild.AcceptInput("Color", sColor, null, null)
					else if(sChildModel.find("bomb_mechanism"))
						hChild.AcceptInput("Color", sColor, null, null)
				}
			}

			if(iState == 0)
			{
				if(bPaintable)
					Color(true)
			}
			else if(iState == 2)
			{
				if(bPaintable)
					Color(false)

				local angRotation = self.GetAbsAngles()
				local Players = []
				for(local hPlayer; hPlayer = FindByClassnameWithin(hPlayer, "player", self.GetOrigin() + RotatePosition(Vector(), angRotation, Vector(130, 0, 32)), 80);)
				{
					Players.append(hPlayer)
					if(hPlayer.IsAlive() && hPlayer.GetTeam() != self.GetTeam() && PlayersLast.find(hPlayer) == null)
					{
						EmitSoundEx({
							sound_name  = TARGETANK_SND_HIT
							sound_level = 76
							filter_type = RECIPIENT_FILTER_GLOBAL
							entity      = self
						})
						local vecLaunch = QAngle(-25, angRotation.y, 0).Forward()
						hPlayer.SetAbsVelocity(vecLaunch * 1200)
						hPlayer.TakeDamageCustom(self, self, null, Vector(), Vector(), TARGETANK_IMPACT_DAMAGE, DMG_CLUB, TF_DMG_CUSTOM_CHARGE_IMPACT)
					}
				}
				PlayersLast = Players
			}
			return -1
		}
		TankExt.AddThinkToEnt(hTank, "Think")
	}
})

TankExt.NewTankScript("targetank_color", {
	OnSpawn = function(hTank, sName, hPath)
	{
		hTank.GetScriptScope().Paintable <- null
		TankExt.TankScripts.targetank.OnSpawn(hTank, sName, hPath)
	}
})