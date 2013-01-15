class Blast_Disco extends Blast;

var float MaxDiscoTime;

function DoEffect()
{
	local RPGEffect Effect;
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

			Effect = class'Effect_Disco'.static.Create(C.Pawn, Instigator.Controller, damageScale * MaxDiscoTime);
			if(Effect != None)
				Effect.Start();
		}
	}
	
	Destroy();
}

defaultproperties
{
	bAffectInstigator=True
	bBotsBeAfraid=False
	ChargeTime=2.000000
	Radius=2000.000000
    MaxDiscoTime=15.00
	ChargeEmitterClass=class'FX_BlastCharger_Disco'
	ExplosionClass=class'FX_BlastExplosion_Disco'
}
