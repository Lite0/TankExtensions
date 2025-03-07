local SENTRY_FLAG_INVULN        = 2
local SENTRY_FLAG_UPGRADABLE    = 4
local SENTRY_FLAG_INFINITE_AMMO = 8
local SENTRY_FLAG_MINI_SIGSEGV  = 64

local SENTRYTANK_VALUES_TABLE = {
	SENTRYTANK_SENTRY_HEALTH         = 700
	SENTRYTANK_SENTRY_DEFAULTUPGRADE = 2
	SENTRYTANK_SENTRY_FLAGS          = SENTRY_FLAG_INVULN | SENTRY_FLAG_INFINITE_AMMO
}
foreach(k,v in SENTRYTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

TankExt.NewTankType("sentrytank", {
	function OnSpawn()
	{
		self.RemoveEFlags(EFL_DONTBLOCKLOS)
		local SpawnSentry = @(vecOrigin, angRotation, iLevel)
		{
			Entity = SpawnEntityFromTable("obj_sentrygun",
			{
				origin         = vecOrigin
				angles         = self.GetAbsAngles() + angRotation
				defaultupgrade = iLevel
				teamnum        = self.GetTeam()
				spawnflags     = SENTRYTANK_SENTRY_FLAGS
				vscripts       = "tankextensions/misc/sentry_removesapper"
			})
			Angles = angRotation
		}
		local Sentries = []
		Sentries.append(SpawnSentry(Vector(74, 0, 158), QAngle(), SENTRYTANK_SENTRY_DEFAULTUPGRADE))
		Sentries.append(SpawnSentry(Vector(-60, 0, 158), QAngle(0, 180, 0), SENTRYTANK_SENTRY_DEFAULTUPGRADE))
		foreach(i, SentryTable in Sentries)
		{
			Sentries[i] = SentryTable.Entity
			SentryTable.Entity.SetLocalAngles(SentryTable.Angles)
			SentryTable.Entity.AcceptInput("SetHealth", SENTRYTANK_SENTRY_HEALTH.tostring(), null, null)
		}
		TankExt.SetParentArray(Sentries, self)
		function Think()
		{
			foreach(hSentry in Sentries)
				for(local hRocket; hRocket = FindByClassnameWithin(hRocket, "tf_projectile_sentryrocket", hSentry.GetAttachmentOrigin(2), 32);)
					if(!(hRocket.GetEFlags() & EFL_NO_MEGAPHYSCANNON_RAGDOLL) && hRocket.GetOwner() == hSentry)
					{
						hRocket.AddEFlags(EFL_NO_MEGAPHYSCANNON_RAGDOLL)
						local hTank = self
						TankExt.DelayFunction(hRocket, null, 0.2, @() self.SetOwner(hTank))
					}
		}
	}
})