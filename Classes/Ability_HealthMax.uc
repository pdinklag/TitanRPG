class Ability_HealthMax extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	local int HealthBonus;
	
	Super.ModifyPawn(Other);
	
	HealthBonus = AbilityLevel * int(BonusPerLevel);

	Other.HealthMax = Other.default.HealthMax + HealthBonus;
	Other.SuperHealthMax = Other.HealthMax + (Other.default.SuperHealthMax - Other.default.HealthMax);
}

simulated function string DescriptionText()
{
	return Repl(Super.DescriptionText(), "$1", int(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Max Health"
	StatName="Max Health Bonus"
	Description="Increases your maximum health by $1 per level. Your starting health is not affected by this ability."
	MaxLevel=3
	StartingCost=5
	BonusPerLevel=10
	Category=class'AbilityCategory_Health'
}
