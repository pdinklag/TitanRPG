class Ability_VehicleEject extends RPGAbility;

var config array<class<DamageType> > ProtectAgainst;
var config float VehicleCooldown; //can't enter a vehicle before this time has passed
var config bool bResetTranslocatorCharge;

var float LastEjectionTime;
var float NextVehicleTime;

var Sound CantEnterSound;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientNotifyCooldown;
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(HasJustEjected() && class'Util'.static.InArray(DamageType, ProtectAgainst) >= 0)
		Damage = 0;
}

function bool CanEjectDriver(Vehicle KilledVehicle)
{
	return (AbilityLevel == 1 && ONSWeaponPawn(KilledVehicle) == None) || AbilityLevel >= 2;
}

function bool HasJustEjected()
{
	return ((Level.TimeSeconds - LastEjectionTime) < 2.0f);
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	local TransLauncher TL;
	local Pawn Driver;
	local Vehicle V;
	local vector EjectVel;

	V = Vehicle(Killed);
	
	if(V == None)
		return false; //to fix the weird survival / spectator bug

	Driver = V.Driver;

	if(DamageType == class'DamTypeSelfDestruct' || Driver == None || !CanEjectDriver(V))
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
	
	if(VehicleCooldown > 0)
	{
		NextVehicleTime = Level.TimeSeconds + VehicleCooldown;
		ClientNotifyCooldown(VehicleCooldown);
	}
	
	if(bResetTranslocatorCharge)
	{
		TL = TransLauncher(Driver.FindInventoryType(class'TransLauncher'));
		if(TL != None)
		{
			//TL.DrainCharges(); //BR-like is a little too harsh, setting ammo to -1
			TL.AmmoChargeF = 0;
			TL.RepAmmo = 0;
			TL.bDrained = false;
			TL.Enable('Tick'); //start recharging
		}
	}
	
	return false; //NOT saving the vehicle
}

function bool CanEnterVehicle(Vehicle V)
{
	if(Level.TimeSeconds < NextVehicleTime)
	{
		if(RPRI.Controller.IsA('PlayerController'))
			PlayerController(RPRI.Controller).ClientPlaySound(CantEnterSound,,, SLOT_Interface);
		
		return false;
	}

	return true;
}

simulated function ClientNotifyCooldown(float Time)
{
	//simulated client-side so status icon can use it correctly
	NextVehicleTime = Level.TimeSeconds + Time;
}

defaultproperties
{
	StatusIconClass=class'StatusIcon_VehicleEject'
	CantEnterSound=Sound'TitanRPG.Interface.CantUse'
	bResetTranslocatorCharge=True
	VehicleCooldown=5.00
	AbilityName="Ejector Seat"
	Description="Ejects you from your vehicle when it's destroyed. You have to wait a short while before you can enter another vehicle."
	LevelDescription(0)="Level 1 ejects you from the driver's seat when your vehicle gets destroyed."
	LevelDescription(1)="Level 2 also ejects you from any other seat in a vehicle as well as from defensive turrets."
	MaxLevel=2
	bUseLevelCost=true
	LevelCost(0)=20
	LevelCost(1)=10
	ProtectAgainst(0)=class'Onslaught.DamTypeONSVehicle'
	ProtectAgainst(1)=class'Onslaught.DamTypeONSVehicleExplosion'
	ProtectAgainst(2)=class'Onslaught.DamTypeDestroyedVehicleRoadKill'
	ProtectAgainst(3)=class'Onslaught.DamTypeTankShell'
	ProtectAgainst(4)=class'OnslaughtBP.DamTypeShockTankShockBall'
	ProtectAgainst(5)=class'OnslaughtBP.DamTypeArtilleryShell'
	ProtectAgainst(6)=class'OnslaughtFull.DamTypeMASCannon'
	ProtectAgainst(7)=class'OnslaughtFull.DamTypeIonTankBlast'
	ProtectAgainst(8)=class'XWeapons.DamTypeIonBlast'
	ProtectAgainst(9)=class'XWeapons.DamTypeRedeemer'
	ProtectAgainst(10)=class'DamTypeTitanUltima'
	ProtectAgainst(11)=class'DamTypeUltima'
	Category=class'AbilityCategory_Vehicles'
}
