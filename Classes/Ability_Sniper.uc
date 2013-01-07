class Ability_Sniper extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	local class<RPGWeapon> RPGWeaponClass;
	
	Super.ModifyPawn(Other);

	if(AbilityLevel >= 2)
		RPGWeaponClass = class'Weapon_Stealth';
	else
		RPGWeaponClass = class'RPGWeapon';
	
	RPRI.QueueWeapon(
		class'ClassicSniperRifle',
		RPGWeaponClass,
		RPGWeaponClass.static.GetRandomModifierLevel()
	);
}

defaultproperties
{
	AbilityName="Sniper"
	Description=""
	LevelDescription(0)="Level 1: You are granted a Sniper Rifle when you spawn."
	LevelDescription(1)="Level 2: You are granted a Sniper Rifle of Stealth when you spawn."
	StartingCost=15
	CostAddPerLevel=5
	MaxLevel=2
	Category=class'AbilityCategory_Weapons'
}
