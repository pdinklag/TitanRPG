class AbilityDamageBalance extends RPGAbility;

function ModifyRPRI()
{
	RPRI.Attack += AbilityLevel * int(BonusPerLevel * 200.0);
	RPRI.Defense += AbilityLevel * int(BonusPerLevel * 200.0);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Damage Balance"
	Description="Increases all damage you do and reduces all damage you take by $1 per level."
	MaxLevel=6
	StartingCost=5
	BonusPerLevel=0.025000
}
