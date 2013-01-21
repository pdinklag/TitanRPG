class Ability_VehicleLock extends RPGAbility;

function UnModifyVehicle(Vehicle V)
{
	if(V.IsA('ONSWeaponPawn'))
		V = ONSWeaponPawn(V).VehicleBase;

	if(V != None && V.NumPassengers() <= 1)
		V.bTeamLocked = true;
}

defaultproperties
{
	AbilityName="Vehicle Lock"
	Description="Locks your vehicle for your team when you leave it so it cannot be stolen."
	MaxLevel=1
	StartingCost=10
	Category=class'AbilityCategory_Vehicles'
}
