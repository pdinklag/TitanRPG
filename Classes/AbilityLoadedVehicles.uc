class AbilityLoadedVehicles extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	local Weapon NewWeapon;
	local RPGWeapon RPGWeapon;

	Super.ModifyPawn(Other);

	if(AbilityLevel >= 2)
	{
		newWeapon = Other.spawn(class'RPGLinkGun', Other,,, rot(0,0,0));
		
		if(newWeapon == None)
			return;
			
		while(newWeapon.isA('RPGWeapon'))
			newWeapon = RPGWeapon(newWeapon).ModifiedWeapon;

		RPGWeapon = Other.spawn(class'WeaponRepair', Other,,, rot(0,0,0));
		
		if(RPGWeapon == None)
			return;
		
		RPGWeapon.Generate(None);
		RPGWeapon.SetModifiedWeapon(newWeapon, true);
		RPGWeapon.GiveTo(Other);
	}
}

defaultproperties
{
	AbilityName="Vehicle Toolbox"
	Description="Grants items useful to vehicle users."
	LevelDescription(1)="Level 2 grants the Repair Link Gun when you spawn."
	MaxLevel=3
	StartingCost=10
}
