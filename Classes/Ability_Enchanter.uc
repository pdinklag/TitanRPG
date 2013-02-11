class Ability_Enchanter extends RPGAbility;

//allowed weapon types
var config array<class<Weapon> > ForbiddenWeapons;

function bool ModifyGrantedWeapon(class<Weapon> WeaponClass, out class<RPGWeaponModifier> ModifierClass, out int Modifier) {
    local int x;

    if(ModifierClass == None && class'Util'.static.InArray(WeaponClass, ForbiddenWeapons) == -1) {
        ModifierClass = RPRI.RPGMut.GetRandomWeaponModifier(WeaponClass, None, true);
        
        if(ModifierClass != None) {
            for(x = 0; x < 50; x++) {
                Modifier = ModifierClass.static.GetRandomModifierLevel();
                
                //try to generate a good modifier level
                if((AbilityLevel == 1) ||                  //any on level 1
                   (AbilityLevel == 2 && Modifier >= 0) || //only positive on level 2
                   (AbilityLevel >= 3 && Modifier >= 4))   //+4 or higher on level 3
                {
                    break;
                }
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
