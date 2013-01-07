class Ability_Hotwheels extends RPGAbility;

function ModifyVehicle(Vehicle V)
{
	local ONSWheeledCraft Car;
	
	Car = ONSWheeledCraft(V);
	if(Car != None)
		class'Util'.static.SetVehicleSpeed(Car, 1.0 + BonusPerLevel * float(AbilityLevel));
}

function UnModifyVehicle(Vehicle V)
{
	local ONSWheeledCraft Car;
	
	Car = ONSWheeledCraft(V);
	if(Car != None)
		class'Util'.static.SetVehicleSpeed(Car, 1.0);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Hotwheels"
	Description="Increases the speed of all wheeled vehicles by $1 per level."
	MaxLevel=10
	BonusPerLevel=0.030000
	bUseLevelCost=True
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=5
	LevelCost(3)=10
	LevelCost(4)=10
	LevelCost(5)=15
	LevelCost(6)=15
	LevelCost(7)=15
	LevelCost(8)=10
	LevelCost(9)=10
	Category=class'AbilityCategory_Vehicles'
}
