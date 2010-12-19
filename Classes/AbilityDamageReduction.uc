class AbilityDamageReduction extends RPGAbility;

function ModifyRPRI()
{
	RPRI.Defense += AbilityLevel * int(BonusPerLevel * 200.0);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Damage Reduction"
	Description="Reduces all damage you take by $1 per level."
	MaxLevel=6
	StartingCost=5
	BonusPerLevel=0.025000
}
