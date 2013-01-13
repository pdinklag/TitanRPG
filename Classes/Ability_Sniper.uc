class Ability_Sniper extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);

    if(AbilityLevel < 2) {
        RPRI.QueueWeapon(class'RPGClassicSniperRifle', None, 0);
    } else {
        RPRI.QueueWeapon(class'RPGClassicSniperRifle', class'WeaponModifier_Stealth', 1);
    }
}

defaultproperties
{
	AbilityName="Sniper"
	Description=""
	LevelDescription(0)="Level 1: You are granted the Sniper Rifle when you spawn."
	LevelDescription(1)="Level 2: You are granted the Sniper Rifle of Stealth when you spawn."
	StartingCost=15
	CostAddPerLevel=5
	MaxLevel=2
	Category=class'AbilityCategory_Weapons'
}
