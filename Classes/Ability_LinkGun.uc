class Ability_LinkGun extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);

    if(AbilityLevel < 2) {
        RPRI.QueueWeapon(class'RPGLinkGun', None, 0);
    } else {
        RPRI.QueueWeapon(class'RPGLinkGun', class'WeaponModifier_Repair', 1);
    }
}

defaultproperties
{
	AbilityName="Link Gun"
	Description=""
	LevelDescription(0)="Level 1: You are granted the Link Gun when you spawn."
	LevelDescription(1)="Level 2: You are granted the Repair Link Gun when you spawn."
	StartingCost=15
	CostAddPerLevel=5
	MaxLevel=2
	Category=class'AbilityCategory_Weapons'
}
