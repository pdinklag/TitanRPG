class Ability_VehicleSpeed extends RPGAbility;

struct SpeedBonusStruct
{
	var class<ONSVehicle> VehicleType;
	var float Bonus;
};
var config array<SpeedBonusStruct> SpeedBonus;
var config float FallbackSpeedBonus;

var localized string DescriptionAmendment;

function ModifyVehicle(Vehicle V)
{
	local int i;
	local float Bonus;

	if(ONSVehicle(V) == None)
		return;
	
	Bonus = 0;
	for(i = 0; i < SpeedBonus.Length; i++)
	{
		if(ClassIsChildOf(V.class, SpeedBonus[i].VehicleType))
		{
			Bonus = SpeedBonus[i].Bonus;
			break;
		}
	}
	
	if(Bonus <= 0)
		Bonus = FallbackSpeedBonus;
		
	Bonus = 1.0 + float(AbilityLevel) * Bonus;	
	class'Util'.static.SetVehicleSpeed(V, Bonus);
}

simulated function string DescriptionText()
{
	local int i;
	local float MinBonus, MaxBonus;
	
	MinBonus = 1.0;
	MaxBonus = 0.0;
	
	for(i = 0; i < SpeedBonus.Length; i++)
	{
		if(SpeedBonus[i].Bonus > MaxBonus)
			MaxBonus = SpeedBonus[i].Bonus;
			
		if(SpeedBonus[i].Bonus < MinBonus)
			MinBonus = SpeedBonus[i].Bonus;
	}
	
	if(MinBonus == MaxBonus)
	{
		return repl(
			repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(MinBonus)),
			"$2", "");
	}
	else
	{
		return repl(
			repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(MinBonus) @ "-" @ class'Util'.static.FormatPercent(MaxBonus)),
			"$2", default.DescriptionAmendment);
	}
}

defaultproperties
{
	AbilityName="Quick Vehicles"
	StatName="Vehicle Speed Bonus"
	Description="Increases your vehicle speed by $1 per level$2."
	DescriptionAmendment=", dependent on the vehicle type"
	StartingCost=10
	MaxLevel=10
	FallbackSpeedBonus=0.05
	//NOTE: Order is very important here, as subclasses of the specified vehicle types will also count to offer mod compability!
	//So list the special classes first and the abstracts as fallbacks!!! ~pd
	SpeedBonus(0)=(VehicleType=class'Onslaught.ONSRV',Bonus=0.20) //Scorpion
	SpeedBonus(1)=(VehicleType=class'OnslaughtBP.ONSShockTank',Bonus=0.05) //Paladin
	SpeedBonus(2)=(VehicleType=class'OnslaughtBP.ONSDualAttackCraft',Bonus=0.10) //Cicada
	SpeedBonus(3)=(VehicleType=class'Onslaught.ONSChopperCraft',Bonus=0.20) //Raptor
	SpeedBonus(4)=(VehicleType=class'Onslaught.ONSHoverCraft',Bonus=0.05) //Manta
	SpeedBonus(5)=(VehicleType=class'Onslaught.ONSWheeledCraft',Bonus=0.10) //HellBender, SPMA, MAS, Toilet Car
	SpeedBonus(6)=(VehicleType=class'Onslaught.ONSTreadCraft',Bonus=0.10) //Tanks
	
	Category=class'AbilityCategory_Vehicles'
}
