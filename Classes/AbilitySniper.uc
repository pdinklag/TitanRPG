class AbilitySniper extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	local class<RPGWeapon> RPGWeaponClass;
	local Weapon NewWeapon;
	local RPGWeapon RPGWeapon;
	
	Super.ModifyPawn(Other);

	newWeapon = Other.Spawn(class'ClassicSniperRifle', Other,,, rot(0,0,0));
	
	if(newWeapon == None)
		return;
		
	while(newWeapon.isA('RPGWeapon'))
		newWeapon = RPGWeapon(newWeapon).ModifiedWeapon;

	if(AbilityLevel >= 2)
		RPGWeaponClass = class'WeaponStealth';
	else
		RPGWeaponClass = class'RPGWeapon';

	RPGWeapon = Other.spawn(RPGWeaponClass, Other,,, rot(0,0,0));
	
	if(RPGWeapon == None)
		return;
	
	RPGWeapon.Generate(None);
	
	RPGWeapon.SetModifiedWeapon(newWeapon, true);
	RPGWeapon.GiveTo(Other);
	RPGWeapon.MaxOutAmmo();
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
}
