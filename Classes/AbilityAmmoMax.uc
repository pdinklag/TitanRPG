class AbilityAmmoMax extends RPGAbility;

function ModifyRPRI()
{
	Super.ModifyRPRI();
	
	RPRI.AmmoMax += AbilityLevel * int(BonusPerLevel * 100.0);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Arsenal"
	StatName="Max Ammo Bonus"
	Description="Increases your maximum ammunition for any weapon type (except for super weapons) by $1 per level."
	MaxLevel=10
	StartingCost=5
	BonusPerLevel=0.05
	Category=class'AbilityCategory_Weapons'
}
