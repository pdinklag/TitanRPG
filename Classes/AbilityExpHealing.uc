class AbilityExpHealing extends RPGAbility;

function ModifyRPRI()
{
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
	RequiredAbilities(0)=(AbilityClass=class'AbilityLoadedMedic',Level=1)
	BonusPerLevel=0.010000
}
