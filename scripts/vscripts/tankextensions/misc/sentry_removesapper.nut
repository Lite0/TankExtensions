PrecacheScriptSound("Building_Sentry.Damage")
bHasSapperLast <- false
iHealthLast <- 0
flNextDamage <- 0
SentrySapThink <- function()
{
	local bHasSapper = GetPropBool(self, "m_bHasSapper")
	if(bHasSapper)
	{
		local hSapper = self.FirstMoveChild()
		if(!bHasSapperLast)
		{
			EmitSoundOn("Building_Sentry.Damage", self)
			SetPropEntity(hSapper, "m_hBuilder", null)
			EntFireByHandle(self, "SetHealth", iHealthLast.tostring(), 0.1, null, null)
			EntFireByHandle(hSapper, "RemoveHealth", (hSapper.GetHealth() * 4).tostring(), 8, null, null)
		}
	}
	iHealthLast = self.GetHealth()
	bHasSapperLast = bHasSapper
	return -1
}
TankExt.AddThinkToEnt(self, "SentrySapThink")