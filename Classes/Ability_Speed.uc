class Ability_Speed extends RPGAbility;

var config int ColoredSpeedTrailLevel;

function ModifyPawn(Pawn Other)
{
	local float SpeedModifier;

	Super.ModifyPawn(Other);
	
	SpeedModifier = 1.0 + BonusPerLevel * float(AbilityLevel);
	
	Other.GroundSpeed = Other.default.GroundSpeed * SpeedModifier;
	Other.WaterSpeed = Other.default.WaterSpeed * SpeedModifier;
	Other.AirSpeed = Other.default.AirSpeed * SpeedModifier;
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

function bool ShouldColorSpeedTrail()
{
	return (ColoredSpeedTrailLevel > 0 && AbilityLevel >= ColoredSpeedTrailLevel);
}

defaultproperties
{
	AbilityName="Quickfoot"
	StatName="Speed Bonus"
	Description="Increases your speed by $1 per level in all environments.|The Speed adrenaline combo will stack with this effect."
	MaxLevel=10
	ColoredSpeedTrailLevel=0
	bUseLevelCost=true
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=10
	LevelCost(3)=10
	LevelCost(4)=15
	LevelCost(5)=20
	LevelCost(6)=25
	LevelCost(7)=30
	LevelCost(8)=30
	LevelCost(9)=30
	BonusPerLevel=0.05
	Category=class'AbilityCategory_Movement'
}
