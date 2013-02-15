class Ability_Enchanter extends RPGAbility;

//allowed weapon types
var config array<class<Weapon> > ForbiddenWeapons;

function bool ModifyGrantedWeapon(class<Weapon> WeaponClass, out class<RPGWeaponModifier> ModifierClass, out int Modifier) {
    if(ModifierClass == None && class'Util'.static.InArray(WeaponClass, ForbiddenWeapons) == -1) {
        ModifierClass = RPRI.RPGMut.GetRandomWeaponModifier(WeaponClass, None, true);
        
        if(ModifierClass != None) {
            if(AbilityLevel == 1) {
                Modifier = ModifierClass.static.GetRandomModifierLevel();
            } else if(AbilityLevel == 2) {
                Modifier = ModifierClass.static.GetRandomPositiveModifierLevel();
            } else if(AbilityLevel >= 3) {
                Modifier = ModifierClass.static.GetRandomPositiveModifierLevel(4);
            }
        } else {
            //Well, no modifier available
        }
    }
    
    return Super.ModifyGrantedWeapon(WeaponClass, ModifierClass, Modifier);
}

defaultproperties
{
	AbilityName="Enchanter"
	Description="Weapons that are granted to you when you spawn get enchanted."
	LevelDescription(0)="At level 1, all of your weapons will be randomly enchanted."
	LevelDescription(1)="At level 2, all of your weapons will be enchanted with a positive effect."
	LevelDescription(2)="At level 3, all of your weapons will be enchanted with a +4 effect or higher."
    ForbiddenWeapons(0)=class'XWeapons.ShieldGun'
    ForbiddenWeapons(1)=class'XWeapons.TransLauncher'
    ForbiddenWeapons(2)=class'XWeapons.BallLauncher'
    ForbiddenWeapons(3)=class'XWeapons.Redeemer'
    ForbiddenWeapons(4)=class'XWeapons.Painter'
    ForbiddenWeapons(5)=class'OnslaughtFull.ONSPainter'
	StartingCost=15
	CostAddPerLevel=5
	MaxLevel=3
	Category=class'AbilityCategory_Weapons'
}
