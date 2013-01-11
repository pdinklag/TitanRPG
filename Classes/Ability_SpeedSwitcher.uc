class Ability_SpeedSwitcher extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientModifyWeapon;
}

simulated function ClientModifyWeapon(Weapon Weapon, float Modifier)
{
	Weapon.BringUpTime = Weapon.default.BringUpTime / Modifier;
	Weapon.PutDownTime = Weapon.default.PutDownTime / Modifier;
	Weapon.MinReloadPct = Weapon.default.MinReloadPct / Modifier;
	Weapon.PutDownAnimRate = Weapon.default.PutDownAnimRate * Modifier;
	Weapon.SelectAnimRate = Weapon.default.SelectAnimRate * Modifier;
}

function ModifyWeapon(Weapon Weapon)
{
	local float Modifier;
	
	Modifier = 1.0 + (BonusPerLevel * AbilityLevel);

	Weapon.BringUpTime = Weapon.default.BringUpTime / Modifier;
	Weapon.PutDownTime = Weapon.default.PutDownTime / Modifier;
	Weapon.MinReloadPct = Weapon.default.MinReloadPct / Modifier;
	Weapon.PutDownAnimRate = Weapon.default.PutDownAnimRate * Modifier;
	Weapon.SelectAnimRate = Weapon.default.SelectAnimRate * Modifier;
	
	if(Role == ROLE_Authority)
		ClientModifyWeapon(Weapon, Modifier);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Speed Switcher"
	Description="For each level of this ability, you switch weapons $1 faster."
	StartingCost=15
	CostAddPerLevel=5
	MaxLevel=2
	BonusPerLevel=0.500000
	Category=class'AbilityCategory_Weapons'
}
