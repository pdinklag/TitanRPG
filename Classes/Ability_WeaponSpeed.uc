class Ability_WeaponSpeed extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientModifyWeapon;
}

function ModifyRPRI()
{
	Super.ModifyRPRI();
	RPRI.WeaponSpeed += AbilityLevel * int(BonusPerLevel * 100.0);
}

simulated function ClientModifyWeapon(Weapon Weapon, float Modifier)
{
	class'Util'.static.SetWeaponFireRate(Weapon, Modifier);
}

function ModifyWeapon(Weapon Weapon)
{
	local float Modifier;
	
	Modifier = 1.0 + (BonusPerLevel * AbilityLevel);
    
    class'Util'.static.SetWeaponFireRate(Weapon, Modifier);
	if(Role == ROLE_Authority)
		ClientModifyWeapon(Weapon, Modifier);
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
	Category=class'AbilityCategory_Weapons'
}
