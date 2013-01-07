class Ability_ExpHealing extends RPGAbility;

function ModifyRPRI()
{
	Super.ModifyRPRI();

	RPRI.HealingExpMultiplier += (BonusPerLevel * float(AbilityLevel));
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Experienced Healing"
	Description="Allows you to gain experience for healing teammates with Medic items.|Each level grants an additional $1 experience from healing."
	StartingCost=10
	MaxLevel=9
	RequiredAbilities(0)=(AbilityClass=class'Ability_LoadedMedic',Level=1)
	BonusPerLevel=0.010000
	Category=class'AbilityCategory_Medic'
}
