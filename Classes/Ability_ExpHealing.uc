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
	Description="You gain $1 additional experience from healing per level."
	StartingCost=10
	MaxLevel=9
	RequiredAbilities(0)=(AbilityClass=class'Ability_Medic',Level=1)
	BonusPerLevel=0.01
	Category=class'AbilityCategory_Medic'
}
