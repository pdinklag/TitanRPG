class Ability_WeaponSpeed extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientModifyWeapon, ClientModifyVehicle;
}

function float GetModifier() {
    return 1.0 + (BonusPerLevel * AbilityLevel);
}

simulated function ClientModifyWeapon(Weapon Weapon, float Modifier)
{
	class'Util'.static.SetWeaponFireRate(Weapon, Modifier);
}

function ModifyWeapon(Weapon Weapon)
{
	local float Modifier;
	
	Modifier = GetModifier();
    
    class'Util'.static.SetWeaponFireRate(Weapon, Modifier);
	ClientModifyWeapon(Weapon, Modifier);
}

simulated function ClientModifyVehicle(Vehicle V, float Modifier) {
    class'Util'.static.SetVehicleFireRate(V, Modifier);
}

function ModifyVehicle(Vehicle V)
{
	local float Modifier;
	
	Modifier = GetModifier();
    
	class'Util'.static.SetVehicleFireRate(V, GetModifier());
	ClientModifyVehicle(V, Modifier);
}

function UnModifyVehicle(Vehicle V)
{
    class'Util'.static.SetVehicleFireRate(V, 1.0);
	ClientModifyVehicle(V, 1.0);    
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
