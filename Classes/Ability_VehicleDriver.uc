class Ability_VehicleDriver extends RPGAbility;

var config int RepairLinkLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		RepairLinkLevel;
}

var localized string RepairLinkLevelDescription;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);

	if(AbilityLevel >= RepairLinkLevel)
	{
		RPRI.QueueWeapon(
			class'RPGLinkGun',
            class'WeaponModifier_Repair',
            class'WeaponModifier_Repair'.static.GetRandomPositiveModifierLevel());
	}
}

simulated function string DescriptionText()
{
	LevelDescription[RepairLinkLevel] = Repl(RepairLinkLevelDescription, "$1", RepairLinkLevel);
	return Super.DescriptionText();
}

defaultproperties
{
	AbilityName="Driver"
	Description="Grants items useful to vehicle users and unlocks vehicle abilities."
	RepairLinkLevelDescription="Level $1 grants the Repair Link Gun when you spawn."
	MaxLevel=3
	StartingCost=10
	RepairLinkLevel=2
	Category=class'AbilityCategory_Vehicles'
}
