//-----------------------------------------------------------
//  When out in the world, this can be used to decoy an avril.
// FOR ANY VEHICLE -pd
//-----------------------------------------------------------
class RPGDecoy extends ONSDecoy;

//var ONSDualAttackCraft ProtectedTarget - OBSOLETE -pd

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	Enable('Tick');
}

simulated event Tick(float dt)
{
	local RPGONSAVRiLRocket Rocket;
	local ONSAttackCraftMissle RaptorMissile;

	Super.Tick(dt);

	if(Role < ROLE_Authority)
		return; //necessary? I dunno but it's making sure -pd
		
	/*
		Since we cannot react on vehicle events (cba to create a wrapper like RPGWeapon),
		we'll check every AVRiLRocket that is in range and make it home it.
	*/
	foreach VisibleCollidingActors(class'RPGONSAVRiLRocket', Rocket, DecoyRange, Location)
	{
		if(Rocket.OverrideTarget == None)
			Rocket.OverrideTarget = Self;
	}
	
	//Raptor missiles
	foreach VisibleCollidingActors(class'ONSAttackCraftMissle', RaptorMissile, DecoyRange, Location)
		RaptorMissile.SetHomingTarget(None);
}

simulated event Destroyed()	// Remove it from the Dual Attack craft's array //no, don't -pd
{
	if (DecoyFlightSFX!=None)
		DecoyFlightSFX.Destroy();
}

defaultproperties
{
	DecoyRange=2048.000000
	Speed=1500.000000
	MaxSpeed=2250.000000
	Damage=50.000000
	DamageRadius=250.000000
	MomentumTransfer=10000.000000
	LifeSpan=5.000000
	bBounce=True
}
