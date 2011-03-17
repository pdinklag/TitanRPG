class RPGMineLayerAltFire extends ONSMineLayerAltFire;

simulated function ModeTick(float deltaTime)
{
	local RPGPlayerReplicationInfo RPRI;
	local array<Projectile> Mines;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local rotator Aim;
	local Actor Other;
	local int i;

	if (!bIsFiring)
		return;

       Weapon.GetViewAxes(X,Y,Z);

    // the to-hit trace always starts right in front of the eye
	StartTrace = Instigator.Location + Instigator.EyePosition() + X*Instigator.CollisionRadius;
	Aim = AdjustAim(StartTrace, AimError);
	X = Vector(Aim);
	EndTrace = StartTrace + TraceRange * X;

	Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, false);
	if (Other == None || Other == Instigator)
		HitLocation = EndTrace;

	if (Beam == None)
	{
		if (Weapon.Role == ROLE_Authority)
			Beam = Weapon.spawn(class'ONSMineLayerTargetBeamEffect',,, Instigator.Location);
		else
			foreach Weapon.DynamicActors(class'ONSMineLayerTargetBeamEffect', Beam)
				break;
	}

	if (Beam != None)
		Beam.EndEffect = HitLocation;

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
	if(RPRI != None)
		Mines = RPRI.Mines;
	else
		Mines = Gun.Mines;
	
	if (bDoHit)
		for (i = 0; i < Mines.Length; i++)
		{
			if (Mines[i] == None)
			{
				Mines.Remove(i, 1);
				i--;
			}
			else if (ONSMineProjectile(Mines[i]) != None)
				ONSMineProjectile(Mines[i]).SetScurryTarget(HitLocation);
		}
}

defaultproperties
{
}
