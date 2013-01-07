class Ability_JumpZ extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	Other.JumpZ = Other.default.JumpZ * (1.0 + BonusPerLevel * float(AbilityLevel));
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Power Jump"
	StatName="Jump Height Bonus"
	Description="Increases your jumping height by $1 per level.|The Speed adrenaline combo will stack with this effect."
	MaxLevel=8
	bUseLevelCost=true
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=5
	LevelCost(3)=5
	LevelCost(4)=10
	LevelCost(5)=10
	LevelCost(6)=10
	LevelCost(7)=10
	BonusPerLevel=0.050000
	Category=class'AbilityCategory_Movement'
}
