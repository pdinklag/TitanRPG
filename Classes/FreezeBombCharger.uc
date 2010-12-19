class FreezeBombCharger extends BlastCharger;

var config float MaxFreezeTime;

function DoEffect()
{
	local float damageScale, dist;
	local vector dir;
	local Controller C;
	local NullEntropyInv Inv;

	if (Instigator == None && InstigatorController != None)
		Instigator = InstigatorController.Pawn;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (C.Pawn != None && C.Pawn.Health > 0 &&
				(bAffectInstigator || (C.Pawn != Instigator && !C.SameTeamAs(Instigator.Controller))) &&
				VSize(C.Pawn.Location - Location) < Radius && FastTrace(C.Pawn.Location, Location))
		{
			if (Level.TimeSeconds > C.Pawn.SpawnTime + DeathMatch(Level.Game).SpawnProtectionTime) 
			{
				dir = C.Pawn.Location - Location;
				dist = FMax(1,VSize(dir));
				damageScale = 1 - FMax(0,dist/Radius);

				if(!C.Pawn.isA('Vehicle') && class'WeaponFreeze'.static.canTriggerPhysics(C.Pawn) 
					&& (C.Pawn.FindInventoryType(class'NullEntropyInv') == None))
				{
					Inv = spawn(class'NullEntropyInv', C.Pawn,,, rot(0,0,0));
					if(Inv != None)
					{
						Inv.LifeSpan = (damageScale * MaxFreezeTime * 3);	
						Inv.Modifier = (damageScale * MaxFreezeTime * 3);	// *3 because the NullEntropyInv divides by 3
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
	bAffectInstigator=False
	bBotsBeAfraid=True
	ChargeTime=2.000000
	MaxFreezeTime=15.000000
	Radius=2000.000000
	ChargeEmitterClass=class'FreezeBombChargeEmitter'
	ExplosionClass=class'FreezeBombExplosion'
}
