local BLIMP_VALUES_TABLE = {
	BLIMP_MODEL = "models/bots/boss_bot/boss_blimp_pure.mdl"
	BLIMP_SKIN_RED = 0
	BLIMP_SKIN_BLUE = 1
}
foreach(k,v in BLIMP_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(BLIMP_MODEL)

TankExt.NewTankScript("blimp", {
	OnSpawn = function(hTank, sName, hPath)
	{
		hTank.SetAbsAngles(QAngle(0, hTank.GetAbsAngles().y, 0))
		TankExt.SetTankModel(hTank, BLIMP_MODEL)
		hTank.SetSkin(hTank.GetTeam() == 3 ? BLIMP_SKIN_BLUE : BLIMP_SKIN_RED)
		for(local hChild = hTank.FirstMoveChild(); hChild != null; hChild = hChild.NextMovePeer())
			hChild.DisableDraw()

		local hTank_scope = hTank.GetScriptScope()
		local flSpeed = GetPropFloat(hTank, "m_speed")
		hTank_scope.hTrackTrain <- SpawnEntityFromTable("func_tracktrain", {
			origin = hTank.GetOrigin()
			speed = flSpeed
			startspeed = flSpeed
			target = hPath.GetName()
		})
		hTank_scope.flLastSpeed <- flSpeed
		hTank_scope.Think <- function()
		{
			if(self.GetModelName() != BLIMP_MODEL)
				TankExt.SetTankModel(self, BLIMP_MODEL)

			local vecTrackTrain = hTrackTrain.GetOrigin()
			self.SetAbsOrigin(vecTrackTrain)
			self.GetLocomotionInterface().Reset()

			local flSpeed = GetPropFloat(self, "m_speed")
			if(flSpeed == 0) flSpeed = 0.001
			if(flSpeed != flLastSpeed)
			{
				flLastSpeed = flSpeed
				SetPropFloat(hTrackTrain, "m_flSpeed", flSpeed)
			}
			return -1
		}
		AddThinkToEnt(hTank, "Think")
	}
	OnDeath = function()
	{
		if(hTrackTrain && hTrackTrain.IsValid()) hTrackTrain.Destroy()
		local hDestruction = FindByClassnameNearest("tank_destruction", self.GetOrigin(), 16)
		if(hDestruction && hDestruction.IsValid()) hDestruction.Destroy()
	}
})

TankExt.NewTankScript("blimp_red", {
	OnSpawn = function(hTank, sName, hPath)
	{
		hTank.SetTeam(2)
		EntFireByHandle(hTank, "RunScriptCode", "SetPropBool(self, `m_bGlowEnabled`, true)", 0.1, null, null)
		TankExt.TankScripts.blimp.OnSpawn(hTank, sName, hPath)
	}
	OnDeath = TankExt.TankScripts.blimp.OnDeath
})