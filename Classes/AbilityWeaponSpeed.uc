class AbilityWeaponSpeed extends RPGAbility;

function ModifyRPRI()
{
	Super.ModifyRPRI();

	RPRI.WeaponSpeed += AbilityLevel * int(BonusPerLevel * 100.0);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Weapon Speed"
	StatName="Weapon Speed Bonus"
	Description="Increases your firing rate for all weapons by $1 per level.|The Berserk adrenaline Combo will stack with this effect."
	MaxLevel=10
	StartingCost=5
	BonusPerLevel=0.05
}
