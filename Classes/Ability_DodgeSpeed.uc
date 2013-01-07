class Ability_DodgeSpeed extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	if(Other.IsA('xPawn'))
	{
		xPawn(Other).DodgeSpeedFactor = Other.default.DodgeSpeedFactor * (1.0 + BonusPerLevel * float(AbilityLevel));
		xPawn(Other).DodgeSpeedZ = Other.default.DodgeSpeedZ * (1.0 + 0.5 * BonusPerLevel * float(AbilityLevel));
	}
}

simulated function string DescriptionText()
{
	return repl(
		repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
		"$2", class'Util'.static.FormatPercent(BonusPerLevel * 0.5));
}

defaultproperties
{
	AbilityName="Power Dodge"
	StatName="Dodge Speed Bonus"
	Description="Increases your dodge speed by $1 per level (dodge height by $2 per level)."
	MaxLevel=10
	StartingCost=5
	BonusPerLevel=0.05
	Category=class'AbilityCategory_Movement'
}
