class AbilityVehicleEject extends RPGAbility;

var config array<class<DamageType> > ProtectAgainst;

var float LastEjectionTime;

function bool ProtectsAgainst(class<DamageType> DamageType)
{
	return (class'Util'.static.InArray(DamageType, ProtectAgainst) >= 0);
}

function bool CanEjectDriver(Vehicle KilledVehicle)
{
	return (AbilityLevel == 1 && ONSWeaponPawn(KilledVehicle) == None) || AbilityLevel >= 2;
}

function bool HasJustEjected()
{
	return ((Level.TimeSeconds - LastEjectionTime) < 2.0f);
}

//Let's try a mix of fluffy's and BM's approaches
function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	local Pawn Driver;
	local Vehicle V;
	local vector EjectVel;

	V = Vehicle(Killed);
	
	if(V == None)
		return false; //to fix the weird survival / spectator bug

	Driver = V.Driver;

	if(Driver == None || !CanEjectDriver(V))
		return false;
	
	if(HasJustEjected())
		return false;

	V.KDriverLeave( true );

	EjectVel = VRand();
	EjectVel.Z = 0;
	EjectVel = (Normal(EjectVel) * 0.2 + Vect(0, 0, 1)) * class'ONSHoverBike'.default.EjectMomentum;

	Driver.Velocity = EjectVel;
	Driver.PlayTeleportEffect( false, false);
	
	LastEjectionTime = Level.TimeSeconds;
	
	return false; //NOT saving the vehicle
}

defaultproperties
{
	AbilityName="Ejector Seat"
	Description="Ejects you from your vehicle when it's destroyed."
	LevelDescription(0)="Level 1 ejects you from the driver's seat when your vehicle gets destroyed."
	LevelDescription(1)="Level 2 also ejects you from any other seat in a vehicle as well as from defensive turrets."
	MaxLevel=2
	bUseLevelCost=true
	LevelCost(0)=20
	LevelCost(1)=10
	RequiredAbilities(0)=(AbilityClass=class'AbilityVehicleArmor',Level=1)
	ProtectAgainst(0)=class'Onslaught.DamTypeONSVehicleExplosion'
	ProtectAgainst(1)=class'Onslaught.DamTypeDestroyedVehicleRoadKill'
	ProtectAgainst(2)=class'Onslaught.DamTypeTankShell'
	ProtectAgainst(3)=class'OnslaughtBP.DamTypeShockTankShockBall'
	ProtectAgainst(4)=class'OnslaughtBP.DamTypeArtilleryShell'
	ProtectAgainst(5)=class'OnslaughtFull.DamTypeMASCannon'
	ProtectAgainst(6)=class'OnslaughtFull.DamTypeIonTankBlast'
	ProtectAgainst(7)=class'XWeapons.DamTypeIonBlast'
	ProtectAgainst(8)=class'XWeapons.DamTypeRedeemer'
	ProtectAgainst(9)=class'DamTypeTitanUltima'
	ProtectAgainst(10)=class'DamTypeUltima'
}
