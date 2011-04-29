class Blast_Poison extends Blast;

var config float MinDrain, MaxDrain, DrainTime;

function DoEffect()
{
	local float damageScale, dist;
	local vector dir;
	local Controller C;
	local Effect_Poison Poison;

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
	
				if(Vehicle(C.Pawn) == None)
				{
					Poison = Effect_Poison(class'Effect_Poison'.static.Create(C.Pawn, Instigator.Controller, DrainTime, 1));
					if(Poison != None)
					{
						Poison.PoisonMode = EPoisonMode(1); //1 is PM_Percentage... accessing enum members just won't work??? ~pd
						Poison.PercDrainPerLevel = MinDrain + (damageScale * (MaxDrain - MinDrain)); //1 is PM_Percentage... accessing enum members just won't work??? ~pd
						Poison.Start();
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
	ChargeTime=2.00
	MaxDrain=0.30
	MinDrain=0.15
	DrainTime=15
	Radius=2000
	ChargeEmitterClass=class'FX_BlastCharger_Poison'
	ExplosionClass=class'FX_BlastExplosion_Poison'
}
