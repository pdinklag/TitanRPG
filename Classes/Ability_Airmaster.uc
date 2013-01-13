class Ability_Airmaster extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	Other.AirControl = class'DMMutator'.default.AirControl * (1.0 + BonusPerLevel * float(AbilityLevel));
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Airmaster"
	StatName="Air Control Bonus"
	Description="Increases your air control by $1 per level."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=4
	BonusPerLevel=0.500000
	Category=class'AbilityCategory_Movement'
}
