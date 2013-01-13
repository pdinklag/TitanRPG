class Ability_VehicleRegen extends Ability_Regen;

var config int MaxRegenPerLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		MaxRegenPerLevel;
}

function Timer()
{
	if(Instigator == None || Instigator.Health <= 0)
	{
		SetTimer(0.0f, false);
		return;
	}
	
	if(Instigator.DrivenVehicle != None)
	{
		Instigator.DrivenVehicle.GiveHealth(
			AbilityLevel * Min(int(BonusPerLevel * Instigator.DrivenVehicle.HealthMax), MaxRegenPerLevel),
			Instigator.DrivenVehicle.HealthMax);
	}
}

simulated function string DescriptionText()
{
	return repl(
		repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
		"$2", MaxRegenPerLevel);
}

defaultproperties
{
	AbilityName="Vehicle Regeneration"
	Description="Repairs vehicles by $1 per second per level, maximally by $2 \"health\" per level.|Does not heal past the starting health amount."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=5
	BonusPerLevel=0.01
	MaxRegenPerLevel=8
	Category=class'AbilityCategory_Vehicles'
}
