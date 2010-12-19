class AbilityDamageBonus extends RPGAbility;

function ModifyRPRI()
{
	RPRI.Attack += AbilityLevel * int(BonusPerLevel * 200.0);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Damage Bonus"
	Description="Increases all damage you do by $1 per level."
	MaxLevel=6
	StartingCost=5
	BonusPerLevel=0.025000
}
