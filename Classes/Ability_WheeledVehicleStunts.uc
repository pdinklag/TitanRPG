class Ability_WheeledVehicleStunts extends RPGAbility;

var config float MaxForce;
var config float ForceLevelMultiplier;
var config float MaxSpin;
var config float SpinLevelMultiplier;
var config float JumpChargeTime;
var config float ChargeLevelMultiplier; //really a divisor, since it will be fractional

var struct BackupStruct
{
	var bool bAllowAirControl;
	var bool bAllowChargingJump;
	var bool bSpecialHUD;
	var float MaxJumpForce;
	var float MaxJumpSpin;
	var float JumpChargeTime;
	var bool bHasHandbrake;
} Backup;

replication
{
	reliable if(Role == ROLE_Authority)
		MaxForce, ForceLevelMultiplier,
		MaxSpin, SpinLevelMultiplier,
		JumpChargeTime, ChargeLevelMultiplier;
	
	reliable if(Role == ROLE_Authority)
		ClientModifyVehicle;
}

simulated function ClientModifyVehicle(ONSWheeledCraft Wheels)
{
	Wheels.bAllowAirControl = true;
	Wheels.bAllowChargingJump = true;
	Wheels.bSpecialHUD = true;
	Wheels.MaxJumpForce = MaxForce * (1.0f + float(AbilityLevel - 1) * ForceLevelMultiplier);
	Wheels.MaxJumpSpin = MaxSpin * (1.0f + float(AbilityLevel - 1) * SpinLevelMultiplier);
	Wheels.JumpChargeTime = JumpChargeTime * (1.0f + float(AbilityLevel - 1) * SpinLevelMultiplier);
	Wheels.bHasHandbrake = false;
}

function ModifyVehicle(Vehicle V)
{
	local ONSWheeledCraft Wheels;
	
	Wheels = ONSWheeledCraft(V);
	if (Wheels == None)
		return;

	Backup.bAllowAirControl = Wheels.bAllowAirControl;
	Backup.bAllowChargingJump = Wheels.bAllowChargingJump;
	Backup.bSpecialHUD = Wheels.bSpecialHUD;
	Backup.MaxJumpForce = Wheels.MaxJumpForce;
	Backup.MaxJumpSpin = Wheels.MaxJumpSpin;
	Backup.JumpChargeTime = Wheels.JumpChargeTime;
	Backup.bHasHandbrake = Wheels.bHasHandbrake;

	Wheels.bAllowAirControl = true;
	Wheels.bAllowChargingJump = true;
	Wheels.bSpecialHUD = true;
	Wheels.MaxJumpForce = MaxForce * (1.0f + float(AbilityLevel - 1) * ForceLevelMultiplier);
	Wheels.MaxJumpSpin = MaxSpin * (1.0f + float(AbilityLevel - 1) * SpinLevelMultiplier);
	Wheels.JumpChargeTime = JumpChargeTime * (1.0f + float(AbilityLevel - 1) * SpinLevelMultiplier);
	Wheels.bHasHandbrake = false;
	
	if(Role == ROLE_Authority && Level.NetMode != NM_Standalone)
		ClientModifyVehicle(Wheels);
}

function UnModifyVehicle(Vehicle V)
{
	local ONSWheeledCraft Wheels;

	Wheels = ONSWheeledCraft(V);
	if (Wheels == None)
		return;

	Wheels.bAllowAirControl = Backup.bAllowAirControl;
	Wheels.bAllowChargingJump = Backup.bAllowChargingJump;
	Wheels.bSpecialHUD = Backup.bSpecialHUD;
	Wheels.MaxJumpForce = Backup.MaxJumpForce;
	Wheels.MaxJumpSpin = Backup.MaxJumpSpin;
	Wheels.JumpChargeTime = Backup.JumpChargeTime;
	Wheels.bHasHandbrake = Backup.bHasHandbrake;
}

defaultproperties
{
	MaxForce=200000.000000
	ForceLevelMultiplier=1.500000
	MaxSpin=80.000000
	SpinLevelMultiplier=1.250000
	JumpChargeTime=1.000000
	ChargeLevelMultiplier=0.800000
	AbilityName="Stunt Vehicles"
	Description="With this ability, you can make wheeled vehicles jump.|Hold down the crouch key to charge up and then release to jump.|This ability also grants control of wheeled vehicles in mid-air.|Additional levels provide more spin, momentum, and less charge time."
	StartingCost=10
	MaxLevel=3
	Category=class'AbilityCategory_Vehicles'
}
