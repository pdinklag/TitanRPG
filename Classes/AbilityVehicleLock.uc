class AbilityVehicleLock extends RPGAbility;

function UnModifyVehicle(Vehicle V)
{
	if(V.IsA('ONSWeaponPawn'))
		V = ONSWeaponPawn(V).VehicleBase;

	if(V != None && class'Util'.static.GetNumPassengers(V) <= 1)
		V.bTeamLocked = true;
}

defaultproperties
{
	AbilityName="Vehicle Lock"
	Description="Locks your vehicle for your team when you leave it so it cannot be stolen."
	MaxLevel=1
	StartingCost=10
	RequiredAbilities(0)=(AbilityClass=class'AbilityVehicleArmor',Level=1)
	Category=class'AbilityCategory_Vehicles'
}
