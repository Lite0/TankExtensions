::ROOT <- getroottable()
::CONST <- getconsttable()
::MAX_CLIENTS <- MaxClients().tointeger()

if(!("ConstantNamingConvention" in ROOT))
	foreach(a, b in Constants)
		foreach(k, v in b)
		{
			CONST[k] <- v != null ? v : 0
			ROOT[k] <- v != null ? v : 0
		}

foreach(k, v in ::NetProps.getclass())
	if(k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

foreach(k, v in ::Entities.getclass())
	if(k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::Entities[k].bindenv(::Entities)

foreach(k, v in ::EntityOutputs.getclass())
	if(k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::EntityOutputs[k].bindenv(::EntityOutputs)

local UNOFFICIAL_CONSTANTS = {
	LIFE_ALIVE       = 0
	LIFE_DYING       = 1
	LIFE_DEAD        = 2
	LIFE_RESPAWNABLE = 3
	LIFE_DISCARDBODY = 4

	SND_NOFLAGS                              = 0
	SND_CHANGE_VOL                           = 1
	SND_CHANGE_PITCH                         = 2
	SND_STOP                                 = 4
	SND_SPAWNING                             = 8
	SND_DELAY                                = 16
	SND_STOP_LOOPING                         = 32
	SND_SPEAKER                              = 64
	SND_SHOULDPAUSE                          = 128
	SND_IGNORE_PHONEMES                      = 256
	SND_IGNORE_NAME                          = 512
	SND_DO_NOT_OVERWRITE_EXISTING_ON_CHANNEL = 1024

	CHAN_REPLACE    = -1
	CHAN_AUTO       = 0
	CHAN_WEAPON     = 1
	CHAN_VOICE      = 2
	CHAN_ITEM       = 3
	CHAN_BODY       = 4
	CHAN_STREAM     = 5
	CHAN_STATIC     = 6
	CHAN_VOICE2     = 7
	CHAN_VOICE_BASE = 8
	CHAN_USER_BASE  = 136

	MASK_ALL                   = -1
	MASK_SPLITAREAPORTAL       = 48
	MASK_SOLID_BRUSHONLY       = 16395
	MASK_WATER                 = 16432
	MASK_BLOCKLOS              = 16449
	MASK_OPAQUE                = 16513
	MASK_DEADSOLID             = 65547
	MASK_PLAYERSOLID_BRUSHONLY = 81931
	MASK_NPCWORLDSTATIC        = 131083
	MASK_NPCSOLID_BRUSHONLY    = 147467
	MASK_CURRENT               = 16515072
	MASK_SHOT_PORTAL           = 33570819
	MASK_SOLID                 = 33570827
	MASK_BLOCKLOS_AND_NPCS     = 33570881
	MASK_OPAQUE_AND_NPCS       = 33570945
	MASK_VISIBLE_AND_NPCS      = 33579137
	MASK_PLAYERSOLID           = 33636363
	MASK_NPCSOLID              = 33701899
	MASK_SHOT_HULL             = 100679691
	MASK_SHOT                  = 1174421507

	DAMAGE_NO          = 0
	DAMAGE_EVENTS_ONLY = 1
	DAMAGE_YES         = 2
	DAMAGE_AIM         = 3

	SHAKE_START            = 0
	SHAKE_STOP             = 1
	SHAKE_AMPLITUDE        = 2
	SHAKE_FREQUENCY        = 3
	SHAKE_START_RUMBLEONLY = 4
	SHAKE_START_NORUMBLE   = 5

	TFCOLLISION_GROUP_GRENADES                          = 20
	TFCOLLISION_GROUP_OBJECT                            = 21
	TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT      = 22
	TFCOLLISION_GROUP_COMBATOBJECT                      = 23
	TFCOLLISION_GROUP_ROCKETS                           = 24
	TFCOLLISION_GROUP_RESPAWNROOMS                      = 25
	TFCOLLISION_GROUP_PUMPKIN_BOMB                      = 26
	TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS = 27

	// m_iObjectType
	OBJ_DISPENSER         = 0
	OBJ_TELEPORTER        = 1
	OBJ_SENTRYGUN         = 2
	OBJ_ATTACHMENT_SAPPER = 3

	TF_STUN_NONE                  = 0
	TF_STUN_MOVEMENT              = 1
	TF_STUN_CONTROLS              = 2
	TF_STUN_MOVEMENT_FORWARD_ONLY = 4
	TF_STUN_SPECIAL_SOUND         = 8
	TF_STUN_DODGE_COOLDOWN        = 16
	TF_STUN_NO_EFFECTS            = 32
	TF_STUN_LOSER_STATE           = 64
	TF_STUN_BY_TRIGGER            = 128
	TF_STUN_SOUND                 = 256

	// damagefilter redefinitions
	DMG_USE_HITLOCATIONS                    = DMG_AIRBOAT
	DMG_HALF_FALLOFF                        = DMG_RADIATION
	DMG_CRITICAL                            = DMG_ACID
	DMG_RADIUS_MAX                          = DMG_ENERGYBEAM
	DMG_IGNITE                              = DMG_PLASMA
	DMG_USEDISTANCEMOD                      = DMG_SLOWBURN
	DMG_NOCLOSEDISTANCEMOD                  = DMG_POISON
	DMG_MELEE                               = DMG_BLAST_SURFACE
	DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE = DMG_DISSOLVE
}
foreach(k,v in UNOFFICIAL_CONSTANTS)
	if(!(k in ROOT))
	{
		CONST[k] <- v
		ROOT[k] <- v
	}

////////////////////////////////////////////////////////////////////////////////////////////

::TankExt <- {
	function OnGameEvent_recalculate_holidays(_) { if(GetRoundState() == 3) { delete ::TankExt } }
	function OnGameEvent_mvm_begin_wave(_)
	{
		for(local hPath; hPath = FindByClassname(hPath, "path_track");)
			if(!TankExt.HasTankPathOutput(hPath))
				AddOutput(hPath, "OnPass", "!activator", "RunScriptCode", "TankExt.ApplyTankType(self)", -1, -1)
	}

	ValueOverrides  = {}
	TankScripts     = {}
	TankScriptsWild = {}
	function CreateLoopPaths(PathTable)
	{
		Convars.SetValue("sig_etc_path_track_is_server_entity", 0)
		foreach(sPathName, OriginArray in PathTable)
		{
			if(FindByName(null, format("%s_1", sPathName)))
				continue

			local iArrayLength   = OriginArray.len() - 1
			local vecFinalOrigin = OriginArray.top()
			local iLoopStart
			foreach(i, vecOrigin in OriginArray)
				if(i != iArrayLength && (vecOrigin - vecFinalOrigin).LengthSqr() == 0)
					{ iLoopStart = i; break }

			if(iLoopStart == null)
				return ClientPrint(null, 3, format("\x07ffb2b2[ERROR] Looping path (%s) endpoint does not connect to itself", sPathName))

			local hPath1 = SpawnEntityFromTable("path_track", {
				origin     = OriginArray[0]
				targetname = format("%s_1", sPathName)
				"OnPass#1" : format("%s_2,CallScriptFunction,LoopInitialize,0,-1", sPathName)
				"OnPass#2" : "!activator,RunScriptCode,TankExt.ApplyTankType(self),0,-1"
			})
			local hPath2 = SpawnEntityFromTable("path_track", {
				origin     = OriginArray[1]
				targetname = format("%s_2", sPathName)
				vscripts   = "tankextensions/misc/loopingpath_think"
			})
			local hPath3 = SpawnEntityFromTable("path_track", {
				origin     = Vector(99999)
				targetname = format("%s_3", sPathName)
			})
			TankExt.SetPathConnection(hPath1, hPath2)
			TankExt.SetPathConnection(hPath2, hPath3)
			local hPath_scope = hPath2.GetScriptScope()
			hPath_scope.OriginArray  <- OriginArray
			hPath_scope.sPathName    <- sPathName
			hPath_scope.iArrayLength <- iArrayLength
			hPath_scope.iLoopStart   <- iLoopStart
			SetPropBool(hPath2, "m_bForcePurgeFixedupStrings", true)
			TankExt.AddThinkToEnt(hPath2, "PathThink")
		}
	}
	function CreatePaths(PathTable)
	{
		foreach(sPathName, OriginArray in PathTable)
		{
			if(FindByName(null, format("%s_1", sPathName)))
				continue

			local PathGroup = {}
			local iArrayLength = OriginArray.len() - 1
			foreach(i, vecOrigin in OriginArray)
			{
				PathGroup[i] <- {}
				PathGroup[i].path_track <- {
					origin     = vecOrigin
					targetname = format("%s_%i", sPathName, i + 1)
					target     = i != iArrayLength ? format("%s_%i", sPathName, i + 2) : ""
					OnPass     = "!activator,RunScriptCode,TankExt.ApplyTankType(self),0,-1"
				}
				if(i == iArrayLength - 1)
				{
					local vecOriginNext = OriginArray[i + 1]
					local hPath = FindByClassnameNearest("path_track", vecOriginNext, 1)
					if(hPath != null)
						{ PathGroup[i].path_track.target = hPath.GetName(); break }
				}
			}
			SpawnEntityGroupFromTable(PathGroup)
		}
	}
	function HasTankPathOutput(hPath)
	{
		local iTotalOutputs = GetNumElements(hPath, "OnPass")
		local bHasOutput = false
		for(local i = 0; i <= iTotalOutputs; i++)
		{
			local OutputTable = {}
			GetOutputTable(hPath, "OnPass", OutputTable, i)
			if("parameter" in OutputTable && OutputTable.parameter == "TankExt.ApplyTankType(self)")
				{ bHasOutput = true; break }
		}
		return bHasOutput
	}
	function NewTankType(sName, Table)
	{
		sName = sName.tolower()
		local bWild = sName[sName.len() - 1] == '*'
		if(bWild)
		{
			sName = sName.slice(0, sName.len() - 1)
			TankExt.TankScriptsWild[sName] <- Table
		}
		else
			TankExt.TankScripts[sName] <- Table
	}
	function ApplyTankType(hTank)
	{
		if(!hTank.IsValid() || hTank.GetClassname() != "tank_boss" || hTank.GetEFlags() & EFL_NO_MEGAPHYSCANNON_RAGDOLL) return
		local hPath = caller
		local sTankName = hTank.GetName().tolower()
		hTank.AddEFlags(EFL_NO_MEGAPHYSCANNON_RAGDOLL)
		SetPropBool(hTank, "m_bForcePurgeFixedupStrings", true)

		// legacy
		local UseLegacy = function()
		{
			hTank.RemoveEFlags(EFL_NO_MEGAPHYSCANNON_RAGDOLL)
			hTank.AcceptInput("RunScriptCode", "TankExt.RunTankScript(self)", hTank, hPath)
		}
		if(sTankName in TankScriptsLegacy) UseLegacy()
		else
			foreach(sName, Table in TankScriptsWildLegacy)
				if(startswith(sTankName, sName))
					{ UseLegacy(); break }

		local iCustomParamsBegin = sTankName.find("$")
		if(iCustomParamsBegin != null)
		{
			local CustomParams = split(sTankName.slice(iCustomParamsBegin + 1), "^")
			sTankName = sTankName.slice(0, iCustomParamsBegin)
			hTank.KeyValueFromString("targetname", sTankName)

			local ParamTable = {}
			foreach(CustomParam in CustomParams)
			{
				local Params = split(CustomParam, "|")

				local ParamName = Params[0].tolower()
				local ValidKeyValues = {
					"Model"              : null
					"DisableChildModels" : "tointeger"
					"DisableTracks"      : "tointeger"
					"DisableBomb"        : "tointeger"
					"Color"              : null
					"TeamNum"            : "tointeger"
					"DisableOutline"     : "tointeger"
					"DisableSmokestack"  : "tointeger"
					"NoScreenShake"      : "tointeger"
					"EngineLoopSound"    : null
					"PingSound"          : null
					"Scale"              : "tofloat"
					"NoDestructionModel" : "tointeger"
				}
				foreach(sName, sType in ValidKeyValues)
					if(sName.tolower() == ParamName)
					{
						local Value = Params[1]
						if(sType) Value = Value[sType]()
						ParamTable[sName] <- Value
					}
			}
			ExtraTankKeyValues(hTank, hPath, ParamTable)
		}

		if(sTankName.find("^") != null)
		{
			foreach(sTankName in split(sTankName, "^"))
				ApplyTankTableByName(hTank, hPath, sTankName)
			hTank.KeyValueFromString("targetname", "combinedtank")
		}
		else
			ApplyTankTableByName(hTank, hPath, sTankName)
	}
	function ExtraTankKeyValues(hTank, hPath, TankTable)
	{
		hTank.ValidateScriptScope()
		local hTank_scope = hTank.GetScriptScope()

		if(!("UsedKeyValues" in hTank_scope))
			hTank_scope.UsedKeyValues <- {}

		if(!("MultiOnDeath" in hTank_scope))
		{
			hTank_scope.MultiOnDeath <- []
			SetDestroyCallback(hTank, function()
			{
				foreach(OnDeathFunction in MultiOnDeath)
					if(typeof OnDeathFunction == "function")
						OnDeathFunction()
				if("MultiScope" in this)
					foreach(sName, Table in MultiScope)
						if("OnDeath" in Table)
						{
							Table.self <- self
							Table.OnDeath()
						}
			})
		}

		local Check = @(string) !(string in hTank_scope.UsedKeyValues) && string in TankTable
		local Add   = @(string) hTank_scope.UsedKeyValues[string] <- null

		if(Check("Model"))
		{
			if(typeof TankTable.Model == "string")
				TankTable.Model = { Default = TankTable.Model }
			TankExt.SetTankModel(hTank, {
				Tank       = TankTable.Model.Default
				LeftTrack  = "LeftTrack" in TankTable.Model ? TankTable.Model.LeftTrack : null
				RightTrack = "RightTrack" in TankTable.Model ? TankTable.Model.RightTrack : null
				Bomb       = "Bomb" in TankTable.Model ? TankTable.Model.Bomb : null
			})

			if(!("Damage1" in TankTable.Model))
				TankTable.Model.Damage1 <- TankTable.Model.Default
			if(!("Damage2" in TankTable.Model))
				TankTable.Model.Damage2 <- TankTable.Model.Damage1
			if(!("Damage3" in TankTable.Model))
				TankTable.Model.Damage3 <- TankTable.Model.Damage2

			hTank_scope.sModelLast <- hTank.GetModelName()
			hTank_scope.ModelThink <- function()
			{
				local sModel = self.GetModelName()
				if(sModel != sModelLast)
				{
					local sNewModel = sModel

					if(sModel.find("damage1"))
						sNewModel = TankTable.Model.Damage1
					else if(sModel.find("damage2"))
						sNewModel = TankTable.Model.Damage2
					else if(sModel.find("damage3"))
						sNewModel = TankTable.Model.Damage3
					else
						sNewModel = TankTable.Model.Default

					TankExt.SetTankModel(hTank, { Tank = sNewModel })
					sModel = sNewModel
				}
				sModelLast = sModel
			}
			TankExt.AddThinkToEnt(hTank, "ModelThink")
		}

		local DisableModels = function(iFlags)
		{
			for(local hChild = hTank.FirstMoveChild(); hChild != null; hChild = hChild.NextMovePeer())
			{
				local sChildModel = hChild.GetModelName().tolower()
				if((iFlags & 1 && sChildModel.find("track_")) || (iFlags & 2 && sChildModel.find("bomb_mechanism")))
					hChild.DisableDraw()
			}
		}

		if(Check("DisableChildModels") && TankTable.DisableChildModels == 1)
			DisableModels(3), Add("DisableChildModels")

		if(Check("DisableTracks") && TankTable.DisableTracks == 1)
			DisableModels(1), Add("DisableTracks")

		if(Check("DisableBomb") && TankTable.DisableBomb == 1)
			DisableModels(2), Add("DisableBomb")

		if(Check("Color"))
			TankExt.SetTankColor(hTank, TankTable.Color), Add("Color")

		if(Check("TeamNum"))
		{
			Add("TeamNum")
			hTank.SetTeam(TankTable.TeamNum)
			EntFireByHandle(hTank, "RunScriptCode", "SetPropBool(self, `m_bGlowEnabled`, true)", 0.066, null, null)
		}

		if(Check("DisableOutline") && TankTable.DisableOutline == 1)
		{
			Add("DisableOutline")
			SetPropBool(self, "m_bGlowEnabled", false)
			EntFireByHandle(hTank, "RunScriptCode", "SetPropBool(self, `m_bGlowEnabled`, false)", 0.066, null, null)
		}

		if(Check("DisableSmokestack") && TankTable.DisableSmokestack == 1)
		{
			Add("DisableSmokestack")
			hTank_scope.DisableSmokestackThink <- function()	{ self.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null) }
			TankExt.AddThinkToEnt(hTank, "DisableSmokestackThink")
		}

		if(Check("NoScreenShake") && TankTable.NoScreenShake == 1)
		{
			Add("NoScreenShake")
			hTank_scope.NoScreenShakeThink <- function() { ScreenShake(self.GetOrigin(), 2.0, 5.0, 1.0, 500.0, SHAKE_STOP, true) }
			TankExt.AddThinkToEnt(hTank, "NoScreenShakeThink")
		}

		if(Check("EngineLoopSound"))
		{
			Add("EngineLoopSound")
			local sSound = TankTable.EngineLoopSound
			TankExt.PrecacheSound(sSound)
			StopSoundOn("MVM.TankEngineLoop", hTank)
			local Sound = @(hEnt, iFlags) EmitSoundEx({
				sound_name  = sSound
				channel     = CHAN_STATIC
				sound_level = 85
				entity      = hEnt
				filter_type = RECIPIENT_FILTER_GLOBAL
				flags       = iFlags
			})
			Sound(hTank, SND_NOFLAGS)
			local iDeploySeq = hTank.LookupSequence("deploy")
			hTank_scope.EngineLoopSound <- sSound
			hTank_scope.EngineLoopSoundThink <- function()
			{
				if(iDeploySeq && self.GetSequence() == iDeploySeq)
				{
					iDeploySeq = null
					Sound(hTank, SND_STOP)
				}
			}
			TankExt.AddThinkToEnt(hTank, "EngineLoopSoundThink")
			hTank_scope.MultiOnDeath.append(function()
			{
				Sound(self, SND_STOP)
			})
		}

		if(Check("PingSound"))
		{
			Add("PingSound")
			local sSound = TankTable.PingSound
			TankExt.PrecacheSound(sSound)
			hTank_scope.flLastPingTime <- Time()
			hTank_scope.PingSoundThink <- function()
			{
				local flTime = Time()
				if(flTime - flLastPingTime >= 5.0)
				{
					flLastPingTime = flTime
					StopSoundOn("MVM.TankPing", self)
					EmitSoundEx({
						sound_name  = sSound
						channel     = CHAN_STATIC
						sound_level = 150
						entity      = self
						filter_type = RECIPIENT_FILTER_GLOBAL
					})
				}
			}
			TankExt.AddThinkToEnt(hTank, "PingSoundThink")
		}

		if(Check("Scale"))
			hTank.SetModelScale(TankTable.Scale, -1), Add("Scale")

		if(Check("NoDestructionModel") && TankTable.NoDestructionModel == 1)
		{
			Add("NoDestructionModel")
			hTank_scope.MultiOnDeath.append(function()
			{
				local hDestruction = FindByClassnameNearest("tank_destruction", self.GetOrigin(), 16)
				if(hDestruction) hDestruction.Kill()
			})
		}

		if(Check("NoGravity") && TankTable.NoGravity == 1)
		{
			Add("NoGravity")
			hTank.SetAbsAngles(QAngle(0, hTank.GetAbsAngles().y, 0))
			local flSpeed = GetPropFloat(hTank, "m_speed")
			local hTrackTrain = SpawnEntityFromTable("func_tracktrain", {
				origin     = hTank.GetOrigin()
				speed      = flSpeed
				startspeed = flSpeed
				target     = hPath.GetName()
			})
			local flLastSpeed = flSpeed
			hTank_scope.NoGravityThink <- function()
			{
				local vecTrackTrain = hTrackTrain.GetOrigin()
				self.SetAbsOrigin(vecTrackTrain)
				self.GetLocomotionInterface().Reset()

				local flSpeed = GetPropFloat(self, "m_speed")
				if(flSpeed <= 0) flSpeed = 0.0001
				if(flSpeed != flLastSpeed)
				{
					flLastSpeed = flSpeed
					SetPropFloat(hTrackTrain, "m_flSpeed", flSpeed)
				}
			}
			TankExt.AddThinkToEnt(hTank, "NoGravityThink")
			hTank_scope.MultiOnDeath.append(function()
			{
				if(hTrackTrain && hTrackTrain.IsValid()) hTrackTrain.Kill()
			})
		}
	}
	function ApplyTankTableByName(hTank, hPath, sTankName)
	{
		local TankTable
		local sTableName

		if(sTankName in TankScripts)
		{
			TankTable  = TankScripts[sTankName]
			sTableName = sTankName
		}
		else
			foreach(sName, Table in TankScriptsWild)
				if(startswith(sTankName, sName))
					{
						TankTable  = Table
						sTableName = sName
						local iNameEnd = sTankName.find("|")
						hTank.KeyValueFromString("targetname", iNameEnd ? sTankName.slice(0, iNameEnd) : sTankName)
						break
					}

		if(TankTable)
		{
			hTank.ValidateScriptScope()
			local hTank_scope = hTank.GetScriptScope()

			if(!("MultiScope" in hTank_scope))
			{
				hTank_scope.MultiScope <- {}
				hTank_scope.MultiScopeThink <- function()
				{
					local flTime      = Time()
					local vecOrigin   = self.GetOrigin()
					local angRotation = self.GetAbsAngles()
					local iTeamNum    = self.GetTeam()
					local iHealth     = self.GetHealth()
					local iMaxHealth  = self.GetMaxHealth()
					foreach(sName, Table in MultiScope)
					{
						Table.flTime      <- flTime
						Table.vecOrigin   <- vecOrigin
						Table.angRotation <- angRotation
						Table.iTeamNum    <- iTeamNum
						Table.iHealth     <- iHealth
						Table.iMaxHealth  <- iMaxHealth
						if("Think" in Table) Table.Think()
					}
				}
				TankExt.AddThinkToEnt(hTank, "MultiScopeThink")
			}

			ExtraTankKeyValues(hTank, hPath, TankTable)

			local MakeScope = function()
			{
				local NewScope = {
					self      = hTank
					sTankName = sTankName
					hTankPath = hPath
				}
				hTank_scope.MultiScope[sTableName] <- NewScope
				return NewScope
			}

			if("OnSpawn" in TankTable)
				TankTable.OnSpawn.call(MakeScope())

			if("OnDeath" in TankTable)
			{
				if(!(sTableName in hTank_scope.MultiScope)) MakeScope()
				hTank_scope.MultiScope[sTableName].OnDeath <- TankTable.OnDeath
			}
		}
	}

	//////////////////////// Utilities ////////////////////////

	function SetTankModel(hTank, Model)
	{
		local ApplyModel = function(hEntity, sModel)
		{
			local iModelIndex = PrecacheModel(sModel)
			local sSequence = hEntity.GetSequenceName(hEntity.GetSequence())
			hEntity.SetModel(sModel)
			SetPropInt(hEntity, "m_nModelIndex", iModelIndex)
			SetPropIntArray(hEntity, "m_nModelIndexOverrides", iModelIndex, 0)
			SetPropIntArray(hEntity, "m_nModelIndexOverrides", iModelIndex, 3)
			hEntity.SetSequence(hEntity.LookupSequence(sSequence))
		}
		if(typeof Model == "string")
			{ ApplyModel(hTank, Model); return }

		if("Tank" in Model)
			ApplyModel(hTank, Model.Tank)
		for(local hChild = hTank.FirstMoveChild(); hChild; hChild = hChild.NextMovePeer())
		{
			local sChildModel = hChild.GetModelName().tolower()
			if("LeftTrack" in Model && Model.LeftTrack && sChildModel.find("track_l"))
				ApplyModel(hChild, Model.LeftTrack)
			else if("RightTrack" in Model && Model.RightTrack && sChildModel.find("track_r"))
				ApplyModel(hChild, Model.RightTrack)
			else if("Bomb" in Model && Model.Bomb && sChildModel.find("bomb_mechanism"))
				ApplyModel(hChild, Model.Bomb)
		}
	}
	function SetTankColor(hTank, sColor)
	{
		hTank.AcceptInput("Color", sColor, null, null)
		for(local hChild = hTank.FirstMoveChild(); hChild != null; hChild = hChild.NextMovePeer())
		{
			local sChildModel = hChild.GetModelName().tolower()
			if(sChildModel.find("track_"))
				hChild.AcceptInput("Color", sColor, null, null)
			else if(sChildModel.find("bomb_mechanism"))
				hChild.AcceptInput("Color", sColor, null, null)
		}
	}
	function SetPathConnection(hPath1, hPath2, hPathAlt = null)
	{
		if(hPath2)
		{
			SetPropEntity(hPath1, "m_pnext", hPath2)
			SetPropEntity(hPath2, "m_pprevious", hPath1)
		}
		else
		{
			SetPropEntity(hPath1, "m_pnext", null)
			SetPropEntity(hPath1, "m_pprevious", null)
			SetPropEntity(hPath1, "m_paltpath", null)
			return
		}
		if(hPathAlt)
			SetPropEntity(hPath1, "m_paltpath", hPathAlt)
	}
	function SetValueOverrides(ValueTable)
	{
		ValueOverrides = ValueTable
		foreach(k,v in ValueTable)
			ROOT[k] <- v
	}
	function SetDestroyCallback(entity, callback)
	{
		entity.ValidateScriptScope()
		local scope = entity.GetScriptScope()
		scope.setdelegate({}.setdelegate({
				parent   = scope.getdelegate()
				id       = entity.GetScriptId()
				index    = entity.entindex()
				callback = callback
				_get = function(k)
				{
					return parent[k]
				}
				_delslot = function(k)
				{
					if (k == id)
					{
						entity = EntIndexToHScript(index)
						local scope = entity.GetScriptScope()
						scope.self <- entity
						callback.pcall(scope)
					}
					delete parent[k]
				}
			})
		)
	}
	function SetParentArray(hChildren, hParent, sAttachment = null)
	{
		local iAttachment
		if(sAttachment) iAttachment = hParent.LookupAttachment(sAttachment)
		foreach(hChild in hChildren)
		{
			SetPropEntity(hChild, "m_hMovePeer", hParent.FirstMoveChild())
			SetPropEntity(hParent, "m_hMoveChild", hChild)
			SetPropEntity(hChild, "m_pParent", hParent)
			SetPropEntity(hChild, "m_hMoveParent", hParent)
			SetPropEntity(hChild, "m_Network.m_hParent", hParent)
			SetPropEntity(hChild, "m_hLightingOrigin", hParent)
			if(sAttachment)
				SetPropInt(hChild, "m_iParentAttachment", iAttachment)
		}
	}
	hDelayFunction = null
	function DelayFunction(hTarget, Scope, flDelay, func)
	{
		if(!hDelayFunction)
		{
			hDelayFunction = CreateByClassname("logic_relay")
			SetPropBool(hDelayFunction, "m_bForcePurgeFixedupStrings", true)
			hDelayFunction.DispatchSpawn()
			hDelayFunction.ValidateScriptScope()
			local hDelayFunction_scope = hDelayFunction.GetScriptScope()
			hDelayFunction_scope.DelayTable <- {}
			hDelayFunction_scope.Think <- function()
			{
				local flTime = Time()
				foreach(array, func in DelayTable)
				{
					local hTarget = array[0]
					if(hTarget && !hTarget.IsValid()) delete DelayTable[array]
					else if(flTime >= array[2])
					{
						if(hTarget)
						{
							local Scope = array[1]
							if(!Scope) hTarget.ValidateScriptScope()
							func.call(Scope ? Scope : hTarget.GetScriptScope())
						}
						else func()
						delete DelayTable[array]
					}
				}
				return -1
			}
			TankExt.AddThinkToEnt(hDelayFunction, "Think")
		}
		hDelayFunction.GetScriptScope().DelayTable[[hTarget, Scope, Time() + flDelay]] <- func
	}
	function GetMultiScopeTable(Scope, sName)
	{
		if("MultiScope" in Scope)
			foreach(sScope, Table in Scope.MultiScope)
				if(sScope == sName)
					return Table
		return null
	}
	function NormalizeAngle(target)
	{
		target %= 360.0
		if (target > 180.0)
			target -= 360.0
		else if (target < -180.0)
			target += 360.0
		return target
	}
	function ApproachAngle(target, value, speed)
	{
		target = NormalizeAngle(target)
		value = NormalizeAngle(value)
		local delta = NormalizeAngle(target - value)
		if (delta > speed)
			return value + speed
		else if (delta < -speed)
			return value - speed
		return value
	}
	function VectorAngles(forward)
	{
		local yaw, pitch
		if ( forward.y == 0.0 && forward.x == 0.0 )
		{
			yaw = 0.0
			if (forward.z > 0.0)
				pitch = 270.0
			else
				pitch = 90.0
		}
		else
		{
			yaw = (atan2(forward.y, forward.x) * 180.0 / Pi)
			if (yaw < 0.0)
				yaw += 360.0
			pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / Pi)
			if (pitch < 0.0)
				pitch += 360.0
		}

		return QAngle(pitch, yaw, 0.0)
	}
	function IntersectionBoxBox(xorigin, xmins, xmaxs, yorigin, ymins, ymaxs)
	{
		xmins += xorigin
		xmaxs += xorigin
		ymins += yorigin
		ymaxs += yorigin
		return (xmins.x <= ymaxs.x && xmaxs.x >= ymins.x) &&
			(xmins.y <= ymaxs.y && xmaxs.y >= ymins.y) &&
			(xmins.z <= ymaxs.z && xmaxs.z >= ymins.z)
	}
	function Clamp(value, low, high)
	{
		if (value < low)
			return low
		if (value > high)
			return high
		return value
	}
	function SetEntityColor(entity, r, g, b, a)
	{
		local color = (r) | (g << 8) | (b << 16) | (a << 24)
		NetProps.SetPropInt(entity, "m_clrRender", color)
	}
	function DispatchParticleEffectOn(entity, name, attachment = null)
	{
		if(entity == null) return
		if(name == null)
			{ entity.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null); return }
		local hParticle = CreateByClassname("trigger_particle")
		hParticle.KeyValueFromString("particle_name", name)
		if(attachment)
			hParticle.KeyValueFromString("attachment_name", attachment)
		hParticle.KeyValueFromInt("attachment_type", attachment ? 4 : 1)
		hParticle.KeyValueFromInt("spawnflags", 64)
		hParticle.DispatchSpawn()
		hParticle.AcceptInput("StartTouch", null, entity, entity)
		hParticle.Kill()
	}
	function PrecacheParticle(name)
	{
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = name })
	}
	function IsPlayerStealthedOrDisguised(hPlayer)
	{
		if(!hPlayer.IsPlayer()) return false
		return (hPlayer.IsStealthed() || hPlayer.InCond(TF_COND_DISGUISED)) &&
		!hPlayer.InCond(TF_COND_BURNING) &&
		!hPlayer.InCond(TF_COND_URINE) &&
		!hPlayer.InCond(TF_COND_STEALTHED_BLINK) &&
		!hPlayer.InCond(TF_COND_BLEEDING)
	}
	function PathMaker(hPlayer)
	{
		Convars.SetValue("sig_etc_path_track_is_server_entity", 0)
		local ExistsInScope = @(scope, string) string in scope && (typeof(scope[string]) == "instance" || typeof(scope[string]) == "null" ? (scope[string] != null && scope[string].IsValid()) : true)
		hPlayer.ValidateScriptScope()
		local hPlayer_scope = hPlayer.GetScriptScope()

		local flTimeNext   = 0
		local iGridSize    = 64
		local iButtonsLast = 0
		local iPrintMode   = 0
		local sndPlace     = "buttons/blip1.wav"
		local sndRemove    = "buttons/button15.wav"
		local sndChange    = "buttons/button16.wav"
		local sndComplete1 = "buttons/button18.wav"
		local sndComplete2 = "buttons/button9.wav"
		PrecacheSound(sndPlace)
		PrecacheSound(sndRemove)
		PrecacheSound(sndChange)
		PrecacheSound(sndComplete1)
		PrecacheSound(sndComplete2)

		if(ExistsInScope(hPlayer_scope, "PathArray"))
			foreach(array in hPlayer_scope.PathArray)
				if(array[1].IsValid())
					array[1].Kill()
		hPlayer_scope.PathArray <- []

		if(ExistsInScope(hPlayer_scope, "hGlow")) hPlayer_scope.hGlow.Kill()
		hPlayer_scope.hGlow <- null

		if(ExistsInScope(hPlayer_scope, "hPathVisual")) hPlayer_scope.hPathVisual.Kill()
		hPlayer_scope.hPathVisual <- null

		if(ExistsInScope(hPlayer_scope, "hPathBeam")) hPlayer_scope.hPathBeam.Kill()
		hPlayer_scope.hPathBeam <- null

		if(ExistsInScope(hPlayer_scope, "hPathTrackVisual")) hPlayer_scope.hPathTrackVisual.Kill()
		hPlayer_scope.hPathTrackVisual <- null

		if(ExistsInScope(hPlayer_scope, "hPathHatchVisual")) hPlayer_scope.hPathHatchVisual.Kill()
		hPlayer_scope.hPathHatchVisual <- null

		if(ExistsInScope(hPlayer_scope, "hText")) hPlayer_scope.hText.Kill()
		hPlayer_scope.hText <- null


		hPlayer_scope.PathMakerThink <- function()
		{
			local iButtons         = GetPropInt(self, "m_nButtons")
			local iButtonsChanged  = iButtonsLast ^ iButtons
			local iButtonsPressed  = iButtonsChanged & iButtons
			local iButtonsReleased = iButtonsChanged & (~iButtons)
			iButtonsLast = iButtons
			local vecEye = self.EyePosition()
			local angEye = self.EyeAngles()

			local vecTarget = (vecEye + angEye.Forward() * 128) * (1.0 / iGridSize)
			local GridMath = @(value) floor(value + 0.5) * iGridSize
			vecTarget.x = GridMath(vecTarget.x)
			vecTarget.y = GridMath(vecTarget.y)
			vecTarget.z = GridMath(vecTarget.z)

			local hLastPath
			local PathArrayLength = PathArray.len()
			if(PathArrayLength > 0) hLastPath = PathArray.top()[1]
			local hNearestPathTrack = FindByClassnameNearest("path_track", vecTarget, 1024)

			self.AddCustomAttribute("no_attack", 1, 0.1)

			if(ExistsInScope(this, "hText"))
			{
				local sPlaceText = format("Grid Size : %i\nReload : Cycle Grid Size\nMouse1 : Add Path\nMouse2 : Undo Path\nReload + Crouch : Print Path", iGridSize)
				local sPrintText = format("[Export Method]\nReload : Rafmod\nMouse1 : TankExt\nMouse2 : PopExt+\nCrouch : Cancel", iGridSize)
				hText.KeyValueFromString("message", iPrintMode > 0 ? sPrintText : sPlaceText)
				EntFireByHandle(hText, "Display", null, -1, self, null)
			}
			else
				hText = SpawnEntityFromTable("game_text", {
					targetname = "pathmakertext"
					message    = "test"
					channel    = 0
					color      = "255 255 255"
					holdtime   = 0.3
					x          = -1
					y          = 0.7
				})

			if(iPrintMode > 0)
			{
				if(iPrintMode > 1)
				{
					EmitSoundEx({
						sound_name  = sndComplete2
						entity      = self
						filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
					})
					ClientPrint(self, HUD_PRINTCENTER, "Path printed to console")

					local TextArray = []
					switch(iPrintMode)
					{
						case 2:
							TextArray.append("tank_path = [")
							foreach(k, array in PathArray)
								TextArray.append(format("\tVector(%i, %i, %i)    // tank_path_%i", array[0].x, array[0].y, array[0].z, k + 1))
							TextArray.append("]")
							break
						case 3:
							TextArray.append("\"ExtraTankPath\" : [\n\t[")
							foreach(k, array in PathArray)
								TextArray.append(format("\t\t\"%i %i %i\"    // extratankpath1_%i", array[0].x, array[0].y, array[0].z, k + 1))
							TextArray.append("\t]\n]")
							break
						case 4:
							TextArray.append("ExtraTankPath\n{\n\tName \"tank_path\"")
							foreach(k, array in PathArray)
								TextArray.append(format("\tNode \"%i %i %i\"    // tank_path_%i", array[0].x, array[0].y, array[0].z, k + 1))
							TextArray.append("}")
							break
					}
					local flDelay = 0
					foreach(sText in TextArray)
					{
						local sPrint = sText
						TankExt.DelayFunction(null, null, flDelay += 0.03, function() { ClientPrint(null, HUD_PRINTCONSOLE, sPrint) })
					}

					if(ExistsInScope(this, "hGlow")) hGlow.Kill()
					if(ExistsInScope(this, "hPathVisual")) hPathVisual.Kill()
					if(ExistsInScope(this, "hPathBeam")) hPathBeam.Kill()
					if(ExistsInScope(this, "hPathTrackVisual")) hPathTrackVisual.Kill()
					if(ExistsInScope(this, "hPathHatchVisual")) hPathHatchVisual.Kill()
					if(ExistsInScope(this, "hText")) hText.Kill()
					if(ExistsInScope(this, "PathArray"))
						foreach(array in PathArray)
							if(array[1].IsValid())
								array[1].Kill()

					delete PathMakerThink
					Convars.SetValue("sig_etc_path_track_is_server_entity", 1)
				}

				if(iButtonsPressed & IN_ATTACK)
					iPrintMode = 2
				if(iButtonsPressed & IN_ATTACK2)
					iPrintMode = 3
				if(iButtonsPressed & IN_RELOAD)
					iPrintMode = 4
				if(iButtonsPressed & IN_DUCK)
					iPrintMode = 0

				return -1
			}

			if(iButtonsPressed & IN_RELOAD && iButtons & IN_DUCK)
			{
				EmitSoundEx({
					sound_name  = sndComplete1
					entity      = self
					filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
				})
				iPrintMode = 1
				return -1
			}
			if(iButtonsPressed & IN_ATTACK)
			{
				EmitSoundEx({
					sound_name = sndPlace
					entity = self
					filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
				})
				local hPath = SpawnEntityFromTable("prop_dynamic", {
					origin         = vecTarget
					targetname     = "pathmakerpath"
					model          = "models/editor/axis_helper_thick.mdl"
					disableshadows = 1
				})
				PathArray.append([vecTarget, hPath])
			}
			if(iButtonsPressed & IN_ATTACK2 && PathArrayLength > 0)
			{
				EmitSoundEx({
					sound_name  = sndRemove
					entity      = self
					filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
				})
				local PathArrayEnd = PathArray.pop()
				PathArrayEnd[1].Destroy()
			}
			if(iButtonsPressed & IN_RELOAD)
			{
				EmitSoundEx({
					sound_name  = sndChange
					entity      = self
					filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
				})
				switch(iGridSize)
				{
					case 8:
						iGridSize = 16
						break
					case 16:
						iGridSize = 32
						break
					case 32:
						iGridSize = 64
						break
					case 64:
						iGridSize = 128
						break
					case 128:
						iGridSize = 8
				}
			}

			if(ExistsInScope(this, "hPathVisual"))
				hPathVisual.SetAbsOrigin(vecTarget)
			else
				hPathVisual = SpawnEntityFromTable("prop_dynamic", {
					model          = "models/editor/axis_helper_thick.mdl"
					disableshadows = 1
					rendermode     = 1
					renderfx       = 4
					renderamt      = 127
				})

			if(ExistsInScope(this, "hPathBeam"))
			{
				local Trace = {
					start  = vecTarget
					end    = vecTarget + Vector(0, 0, -8192)
					mask   = MASK_SOLID
					ignore = self
				}
				TraceLineEx(Trace)
				hPathBeam.SetLocalOrigin(Trace.endpos)
			}
			else
			{
				hPathBeam = SpawnEntityFromTable("env_beam", {
					lightningstart = "bignet"
					lightningend   = "bignet"
					boltwidth      = 1
					texture        = "sprites/laserbeam.vmt"
					rendercolor    = "50 50 50"
					spawnflags     = 1
				})
				SetPropEntityArray(hPathBeam, "m_hAttachEntity", hPathBeam, 0)
				SetPropEntityArray(hPathBeam, "m_hAttachEntity", hPathVisual, 1)
			}

			if(ExistsInScope(this, "hPathHatchVisual"))
			{
				if(PathArray.len() > 0)
				{
					local vecLastPath   = PathArray.top()[0]
					local vecHatch      = FindByClassname(null, "func_capturezone").GetCenter()
					local vecLastPathXY = Vector(vecLastPath.x, vecLastPath.y, 0)
					local vecHatchXY    = Vector(vecHatch.x, vecHatch.y, 0)
					local vecDirection  = vecLastPathXY - vecHatchXY
					vecDirection.Norm()
					hPathHatchVisual.SetAbsOrigin(Vector(vecHatch.x, vecHatch.y, vecTarget.z) + vecDirection * 176)
					hPathHatchVisual.SetForwardVector(vecDirection * -1)
				}
			}
			else
				hPathHatchVisual = SpawnEntityFromTable("prop_dynamic", {
					model          = "models/editor/cone_helper.mdl"
					rendercolor    = "255 0 255"
					disableshadows = 1
				})

			if(ExistsInScope(this, "hPathTrackVisual"))
			{
				if(hNearestPathTrack)
				{
					local vecPathTrack     = hNearestPathTrack.GetOrigin()
					local vecPathTrackNext = GetPropEntity(hNearestPathTrack, "m_pnext")
					local vecDirection     = vecPathTrackNext ? GetPropEntity(hNearestPathTrack, "m_pnext").GetOrigin() - vecPathTrack : Vector(0, 0, -1)
					vecDirection.Norm()
					hPathTrackVisual.SetAbsOrigin(vecPathTrack)
					hPathTrackVisual.SetForwardVector(vecDirection)
					EntFireByHandle(hPathTrackVisual.FirstMoveChild(), "SetText", hNearestPathTrack.GetName(), -1, null, null)
				}
			}
			else
			{
				hPathTrackVisual = SpawnEntityFromTable("prop_dynamic", {
					model          = "models/editor/cone_helper.mdl"
					disableshadows = 1
				})
				local hWorldText = SpawnEntityFromTable("point_worldtext", {
					origin      = Vector(0, 0, 12)
					color       = "0 255 255 255"
					font        = 3
					orientation = 1
					textsize    = 6
				})
				TankExt.SetParentArray([hWorldText], hPathTrackVisual)
			}

			if(ExistsInScope(this, "hGlow"))
				SetPropEntity(hGlow, "m_hTarget", hLastPath)
			else
				hGlow = SpawnEntityFromTable("tf_glow", {
					glowcolor  = "255 255 0 255"
					target     = "bignet"
				})

			local flTime = Time()
			if(flTime >= flTimeNext)
			{
				flTimeNext = flTime + 0.5
				local PathArrayMax = PathArray.len() - 1
				foreach(i, array in PathArray)
				{
					if(i == PathArrayMax) break
					local hPathNext = PathArray[i + 1][1]
					local vecDirection = hPathNext.GetOrigin() - array[0]
					vecDirection.Norm()
					local hParticle = SpawnEntityFromTable("info_particle_system", {
						origin       = array[0]
						effect_name  = "spell_lightningball_hit_zap_blue"
						start_active = 1
					})
					hParticle.SetForwardVector(vecDirection)
					SetPropEntityArray(hParticle, "m_hControlPointEnts", hPathNext, 0)
					EntFireByHandle(hParticle, "Kill", null, 0.066, null, null)
				}
			}

			return -1
		}
		TankExt.AddThinkToEnt(hPlayer, "PathMakerThink")
	}
	function AddThinkToEnt(hEntity, sFunction)
	{
		local AddThink = @(ent, func) "_AddThinkToEnt" in ROOT ? ROOT._AddThinkToEnt(ent, func) : ROOT.AddThinkToEnt(ent, func)
		if(hEntity.GetClassname() == "tank_boss")
		{
			local hTank = hEntity
			hTank.ValidateScriptScope()
			local hTank_scope = hTank.GetScriptScope()
			if(!("MultiThink" in hTank_scope))
			{
				hTank_scope.ThinkTable <- {}
				hTank_scope.MultiThink <- function()
				{
					foreach(sName, sFunction in ThinkTable)
						sFunction.call(this)
					return -1
				}
				AddThink(hTank, "MultiThink")
			}

			if(sFunction == null)
				{ hTank_scope.ThinkTable.clear(); return }

			local Function
			if(sFunction in hTank_scope)
				Function = hTank_scope[sFunction]
			else if(sFunction in ROOT)
				Function = ROOT[sFunction]

			hTank_scope.ThinkTable[sFunction] <- Function
		}
		else
			AddThink(hEntity, sFunction)
	}
	function PrecacheSound(sSound)
	{
		if(endswith(sSound, ".wav") || endswith(sSound, ".mp3"))
			ROOT.PrecacheSound(sSound)
		else
			ROOT.PrecacheScriptSound(sSound)
	}
	function SpawnEntityFromTableFast(sClassname, Table)
	{
		local hEnt = CreateByClassname(sClassname)
		foreach(sKey, Value in Table)
			switch(typeof Value)
			{
				case "string"  : hEnt.KeyValueFromString(sKey, Value); break
				case "QAngle"  : hEnt.KeyValueFromString(sKey, format("%f %f %f", Key.x, Key.y, Key.z)); break
				case "Vector"  : hEnt.KeyValueFromVector(sKey, Value); break
				case "float"   : hEnt.KeyValueFromFloat(sKey, Value); break
				case "integer" : hEnt.KeyValueFromInt(sKey, Value); break
				case "bool"    : hEnt.KeyValueFromInt(sKey, Value ? 1 : 0); break
			}
		hEnt.DispatchSpawn()
		return hEnt
	}
}
__CollectGameEventCallbacks(TankExt)
IncludeScript("tankextensions/misc/tankextensions_legacy")