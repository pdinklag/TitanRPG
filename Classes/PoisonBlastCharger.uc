class PoisonBlastCharger extends BlastCharger
	DependsOn(PoisonInv);

var config float MinDrain, MaxDrain, DrainTime;

function DoEffect()
{
	local float damageScale, dist;
	local vector dir;
	local Controller C;
	local PoisonInv Inv;

	if(Instigator == None && InstigatorController != None)
		Instigator = InstigatorController.Pawn;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if ( C.Pawn != None && C.Pawn.Health > 0 &&
				(bAffectInstigator || (C.Pawn != Instigator && !C.SameTeamAs(Instigator.Controller))) &&
				VSize(C.Pawn.Location - Location) < Radius && FastTrace(C.Pawn.Location, Location))
		{
			if(Level.TimeSeconds > C.Pawn.SpawnTime + DeathMatch(Level.Game).SpawnProtectionTime)
			{
				dir = C.Pawn.Location - Location;
				dist = FMax(1, VSize(dir));
				damageScale = 1 - FMax(0, dist / Radius);
	
				if(Vehicle(C.Pawn) == None && C.Pawn.FindInventoryType(class'PoisonInv') == None)
				{
					Inv = Spawn(class'PoisonInv', C.Pawn);
					if(Inv != None)
					{
						Inv.LifeSpan = DrainTime;
						Inv.Modifier = 1;
						Inv.PoisonMode = EPoisonMode(1); //1 is PM_Percentage... accessing enum members just won't work??? ~pd
						Inv.PercDrainPerLevel = MinDrain + (damageScale * (MaxDrain - MinDrain));
						Inv.RPGRules = class'RPGRules'.static.Find(Level.Game);
						Inv.GiveTo(C.Pawn);
					}
				}
			}
		}
	}
	
	Destroy();
}

defaultproperties
{
	bBotsBeAfraid=True
	ChargeTime=2.000000
	MaxDrain=0.300000
	MinDrain=0.150000
	DrainTime=15.000000
	Radius=2000.000000
	ChargeEmitterClass=class'PoisonBlastChargeEmitter'
	ExplosionClass=class'PoisonBlastExplosion'
}
