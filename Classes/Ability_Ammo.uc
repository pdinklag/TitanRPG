class Ability_Ammo extends RPGAbility;

var bool bSuicided;

function ModifyGrantedWeaponAmmo(class<Weapon> WeaponClass, out int Ammo1, out int Ammo2) {
    local int i, StartingAmmo;
    local float Factor;
    local class<WeaponFire> WFClass[2];
    local class<Ammunition> AmmoClass[2];
    
    if(!bSuicided) {
        Factor = (1.0 + AbilityLevel * BonusPerLevel);

        for(i = 0; i < 2; i++) {
            WFClass[i] = WeaponClass.default.FireModeClass[i];
            if(WFClass[i] != None) {
                AmmoClass[i] = WFClass[i].default.AmmoClass;
            }
        }
        
        if(AmmoClass[0] != None) {
            StartingAmmo = int(float(AmmoClass[0].default.InitialAmount) * Factor);
            if(Ammo1 >= 0 && Ammo1 < StartingAmmo) {
                Ammo1 = StartingAmmo;
            }
        }
        
        if(AmmoClass[1] != None && AmmoClass[1] != AmmoClass[0]) {
            StartingAmmo = int(float(AmmoClass[1].default.InitialAmount) * Factor);
            if(Ammo2 >= 0 && Ammo2 < StartingAmmo) {
                Ammo2 = StartingAmmo;
            }
        }
    }
    
    Super.ModifyGrantedWeaponAmmo(WeaponClass, Ammo1, Ammo2);
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	bSuicided = (Killed.Controller == Killer || Killed.Controller == None);

	return Super.PreventDeath(Killed, Killer, DamageType, HitLocation, bAlreadyPrevented);
}

simulated function string DescriptionText() {
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties {
	AbilityName="Arsenal"
	StatName="Ammo Bonus"
	Description="Increases the ammunition for any weapon at spawn by $1 per level. If the weapon is re-granted from Denial or similar and its ammo count is below that value, it will be stocked up to it.||This ability has no effect if you suicided in your previous spawn."
	MaxLevel=10
	StartingCost=5
	BonusPerLevel=0.05
	Category=class'AbilityCategory_Weapons'
}
