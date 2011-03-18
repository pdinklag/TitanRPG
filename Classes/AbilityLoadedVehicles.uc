class AbilityLoadedVehicles extends RPGAbility;

var config int RepairLinkLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		RepairLinkLevel;
}

var localized string RepairLinkLevelDescription;

function ModifyPawn(Pawn Other)
{
	local Weapon NewWeapon;
	local RPGWeapon RPGWeapon;

	Super.ModifyPawn(Other);

	if(AbilityLevel >= RepairLinkLevel)
	{
		newWeapon = Other.spawn(class'RPGLinkGun', Other);
		
		if(newWeapon == None)
			return;
			
		while(newWeapon.isA('RPGWeapon'))
			newWeapon = RPGWeapon(newWeapon).ModifiedWeapon;

		RPGWeapon = Other.spawn(class'WeaponRepair', Other);
		
		if(RPGWeapon == None)
			return;
		
		RPGWeapon.Generate(None);
		RPGWeapon.SetModifiedWeapon(newWeapon, true);
		RPGWeapon.GiveTo(Other);
	}
}

simulated function string DescriptionText()
{
	LevelDescription[RepairLinkLevel] = Repl(RepairLinkLevelDescription, "$1", RepairLinkLevel);
	return Super.DescriptionText();
}

defaultproperties
{
	AbilityName="Vehicle Toolbox"
	Description="Grants items useful to vehicle users."
	RepairLinkLevelDescription="Level $1 grants the Repair Link Gun when you spawn."
	MaxLevel=3
	StartingCost=10
	RepairLinkLevel=2
}
