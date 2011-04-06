class FreezeBombCharger extends BlastCharger;

var config float MaxFreezeTime;

function DoEffect()
{
	local float damageScale, dist;
	local vector dir;
	local Controller C;

	if (Instigator == None && InstigatorController != None)
		Instigator = InstigatorController.Pawn;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (C.Pawn != None && C.Pawn.Health > 0 &&
				(bAffectInstigator || (C.Pawn != Instigator && !C.SameTeamAs(Instigator.Controller))) &&
				VSize(C.Pawn.Location - Location) < Radius && FastTrace(C.Pawn.Location, Location))
		{
			dir = C.Pawn.Location - Location;
			dist = FMax(1,VSize(dir));
			damageScale = 1 - FMax(0,dist/Radius);

			//TODO: Use freeze instead?
			class'EffectNullEntropy'.static.Apply(C.Pawn, Instigator.Controller, damageScale * MaxFreezeTime);
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
