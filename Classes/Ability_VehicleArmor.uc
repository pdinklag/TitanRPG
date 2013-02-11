class Ability_VehicleArmor extends RPGAbility;

var config int MaxHealthBonus; //set to zero for no maximum

var localized string MaxBonusText;

replication
{
	reliable if(Role == ROLE_Authority)
		MaxHealthBonus;
}

function ModifyVehicle(Vehicle V)
{
	local int DefHealth, HealthBonus;
	local float DefLinkHealMult, HealthPct;

	if(ASVehicleFactory(V.ParentFactory) != none)
	{
		DefHealth = ASVehicleFactory(V.ParentFactory).VehicleHealth;
		DefLinkHealMult = ASVehicleFactory(V.ParentFactory).VehicleLinkHealMult;
	}
	else
	{
		DefHealth = V.default.Health;
		DefLinkHealMult = V.default.LinkHealMult;
	}

	HealthPct = float(V.Health) / V.HealthMax;
	HealthBonus = float(DefHealth) * BonusPerLevel * float(AbilityLevel);

	if(MaxHealthBonus > 0)
		HealthBonus = Min(HealthBonus, MaxHealthBonus);

	V.HealthMax = DefHealth + (DefHealth * BonusPerLevel * AbilityLevel);
	V.Health = HealthPct * V.HealthMax;
	V.LinkHealMult = DefLinkHealMult * (V.HealthMax / DefHealth);
}

simulated function string DescriptionText()
{
	local string Text;
	
	Text = repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
	
	if(MaxHealthBonus > 0)
		Text = repl(Text, "$2", repl(MaxBonusText, "$3", MaxHealthBonus));
	else
		Text = repl(Text, "$2", "");
	
	return Text;
}

defaultproperties
{
	AbilityName="Vehicle Armour Bonus"
	Description="Increases the health of any vehicle you use by $1 per level$2."
	MaxBonusText=" (up to a maximal bonus of $3)"
	StartingCost=5
	MaxLevel=10
	MaxHealthBonus=0
	BonusPerLevel=0.050000
	Category=class'AbilityCategory_Vehicles'
}
