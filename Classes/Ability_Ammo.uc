class Ability_Ammo extends RPGAbility;

function bool ModifyGrantedWeapon(class<Weapon> WeaponClass, out class<RPGWeaponModifier> ModifierClass, out int Modifier, out int Ammo1, out int Ammo2) {
    local int i;
    local float Factor;
    local class<WeaponFire> WFClass[2];
    local class<Ammunition> AmmoClass[2];
    
    Factor = (1.0 + AbilityLevel * BonusPerLevel);

    for(i = 0; i < 2; i++) {
        WFClass[i] = WeaponClass.default.FireModeClass[i];
        if(WFClass[i] != None) {
            AmmoClass[i] = WFClass[i].default.AmmoClass;
        }
    }

    if(Ammo1 == 0 && AmmoClass[0] != None) {
        Ammo1 = int(float(AmmoClass[0].default.InitialAmount) * Factor);
    }
    
    if(Ammo2 == 0 && AmmoClass[1] != None && AmmoClass[1] != AmmoClass[0]) {
        Ammo2 = int(float(AmmoClass[1].default.InitialAmount) * Factor);
    }
    
    return true;
}

simulated function string DescriptionText() {
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties {
	AbilityName="Arsenal"
	StatName="Ammo Bonus"
	Description="Increases the ammunition for any weapon granted at spawn by $1 per level."
	MaxLevel=10
	StartingCost=5
	BonusPerLevel=0.05
	Category=class'AbilityCategory_Weapons'
}
