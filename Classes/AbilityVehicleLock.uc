class AbilityVehicleLock extends RPGAbility;

function UnModifyVehicle(Vehicle V)
{
	local Vehicle V0;
	local ONSVehicle OV;
	local int i;

	V0 = V;
	
	//Do not lock if there are any more passengers inside
	if(ONSWeaponPawn(V) != None)
	{
		V = ONSWeaponPawn(V).VehicleBase;
	
		if(V != V0 && V.Driver != None)
			return;
	}

	OV = ONSVehicle(V);
	if(OV != None)
	{
		for(i = 0; i < OV.WeaponPawns.length; i++)
		{
			if(OV.WeaponPawns[i] != V0 && OV.WeaponPawns[i].Driver != None)
				return;
		}
	}

	if(V != None)
		V.bTeamLocked = true;
}

defaultproperties
{
	AbilityName="Vehicle Lock"
	Description="Locks your vehicle for your team when you leave it so it cannot be stolen."
	MaxLevel=1
	StartingCost=10
	RequiredAbilities(0)=(AbilityClass=class'AbilityVehicleArmor',Level=1)
}
