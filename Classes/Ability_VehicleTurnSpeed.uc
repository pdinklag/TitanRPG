class Ability_VehicleTurnSpeed extends RPGAbility;

var Vehicle ClientVehicle; //client-side only

replication
{
	reliable if(Role == ROLE_Authority)
		ClientModifyVehicle, ClientUnModifyVehicle;
}

simulated function ClientModifyVehicle(Vehicle V)
{
	if(Role < ROLE_Authority)
	{
		ClientVehicle = V;
		SetTimer(0.01f, false);
	}
}

simulated function Timer()
{
	if(ClientVehicle != None && Role < ROLE_Authority)
		ModifyVehicle(ClientVehicle);
}

simulated function ClientUnModifyVehicle(Vehicle V)
{
	if(Role < ROLE_Authority)
		UnModifyVehicle(V);
}

simulated function ModifyVehicle(Vehicle V)
{
	local Sync_ONSWeaponRotSpeed Sync;
	local int i;
	local float Modifier;
	
	Modifier = 1.0f + BonusPerLevel * float(AbilityLevel);
	
	if(Role == ROLE_Authority)
	{
		if(V.IsA('ONSVehicle'))
		{
			for(i = 0; i < ONSVehicle(V).Weapons.Length; i++)
			{
				Sync = Spawn(class'Sync_ONSWeaponRotSpeed');
				Sync.Target = ONSVehicle(V).Weapons[i];
				Sync.RotationsPerSecond = ONSVehicle(V).Weapons[i].RotationsPerSecond * Modifier;
				
				ONSVehicle(V).Weapons[i].RotationsPerSecond *= Modifier;
			}
		}
		
		if(V.IsA('ONSWeaponPawn'))
		{
			Sync = Spawn(class'Sync_ONSWeaponRotSpeed');
			Sync.Target = ONSWeaponPawn(V).Gun;
			Sync.RotationsPerSecond = ONSWeaponPawn(V).Gun.RotationsPerSecond * Modifier;
			
			ONSWeaponPawn(V).Gun.RotationsPerSecond *= Modifier;
		}
		
		if(V.IsA('ONSTreadCraft'))
			ONSTreadCraft(V).MaxSteerTorque *= Modifier;
	}
	
	if(V.IsA('ONSHoverCraft'))
	{
		ONSHoverCraft(V).TurnTorqueFactor *= Modifier;
		ONSHoverCraft(V).TurnTorqueMax *= Modifier;
		ONSHoverCraft(V).MaxYawRate *= Modifier;
	}
	
	if(V.IsA('ONSChopperCraft'))
	{
		ONSChopperCraft(V).TurnTorqueFactor *= Modifier;
		ONSChopperCraft(V).TurnTorqueMax *= Modifier;
		ONSChopperCraft(V).MaxYawRate *= Modifier;
	}

	if(Level.NetMode == NM_DedicatedServer)
		ClientModifyVehicle(V);
}

simulated function UnModifyVehicle(Vehicle V)
{
	local Sync_ONSWeaponRotSpeed Sync;
	local int i;

	//Reset
	if(Role == ROLE_Authority)
	{
		if(V.IsA('ONSVehicle'))
		{
			for(i = 0; i < ONSVehicle(V).Weapons.Length; i++)
			{
				ONSVehicle(V).Weapons[i].RotationsPerSecond = ONSVehicle(V).Weapons[i].default.RotationsPerSecond;
				
				Sync = Spawn(class'Sync_ONSWeaponRotSpeed');
				Sync.Target = ONSVehicle(V).Weapons[i];
				Sync.RotationsPerSecond = ONSVehicle(V).Weapons[i].default.RotationsPerSecond;
			}
		}
		
		if(V.IsA('ONSWeaponPawn'))
		{
			ONSWeaponPawn(V).Gun.RotationsPerSecond = ONSWeaponPawn(V).Gun.default.RotationsPerSecond;
			
			Sync = Spawn(class'Sync_ONSWeaponRotSpeed');
			Sync.Target = ONSWeaponPawn(V).Gun;
			Sync.RotationsPerSecond = ONSWeaponPawn(V).Gun.default.RotationsPerSecond;
		}

		if(V.IsA('ONSTreadCraft'))
			ONSTreadCraft(V).MaxSteerTorque = ONSTreadCraft(V).default.MaxSteerTorque;
	}
	
	if(V.IsA('ONSHoverCraft'))
	{
		ONSHoverCraft(V).TurnTorqueFactor = ONSHoverCraft(V).default.TurnTorqueFactor;
		ONSHoverCraft(V).TurnTorqueMax = ONSHoverCraft(V).default.TurnTorqueMax;
		ONSHoverCraft(V).MaxYawRate = ONSHoverCraft(V).default.MaxYawRate;
	}
	
	if(V.IsA('ONSChopperCraft'))
	{
		ONSChopperCraft(V).TurnTorqueFactor = ONSChopperCraft(V).default.TurnTorqueFactor;
		ONSChopperCraft(V).TurnTorqueMax = ONSChopperCraft(V).default.TurnTorqueMax;
		ONSChopperCraft(V).MaxYawRate = ONSChopperCraft(V).default.MaxYawRate;
	}
	
	if(Level.NetMode == NM_DedicatedServer)
		ClientUnModifyVehicle(V);
}

simulated function string DescriptionText() {
    return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Vehicle Turn Speed"
	Description="Increases your vehicle or vehicle turret turning speed by $1 per level."
	bUseLevelCost=True
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=10
	LevelCost(3)=10
	MaxLevel=4
	BonusPerLevel=0.25
	Category=class'AbilityCategory_Vehicles'
}
