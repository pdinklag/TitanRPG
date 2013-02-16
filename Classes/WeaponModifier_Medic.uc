class WeaponModifier_Medic extends WeaponModifier_Heal;

//time until which no ammo will be refunded (used for flak chunks)
var float NoAmmoTime;

/*
function WeaponFire(byte Mode) {
	Identify();
}

function RPGTick(float dt)
{
	//TODO: Find a way for ballistic weapons
	Weapon.MaxOutAmmo();
}
*/

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
    local WeaponFire WF;
    local int Ammo[2];
    local int i;
    
    Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

    //Grant the instigator some ammo back for healing unless he healed himself
    if(
        Damage == 0 &&
        OriginalDamage > 0 &&
        InstigatedBy != Injured &&
        class'Util'.static.SameTeamP(InstigatedBy, Injured) &&
        NoAmmoTime <= Level.TimeSeconds &&
        !DamageType.default.bSuperWeapon &&
        Weapon != None)
    {
        if(DamageType == class'DamTypeShockCombo') {
            //A combo takes 5 primary ammo
            Ammo[0] = 5;
        } else if(DamageType == class'DamTypeBioGlob') {
            //Interpolate goop level from original damage
            Ammo[0] = 1 + (OriginalDamage - class'BioGlob'.default.BaseDamage) / class'BioGlob'.default.Damage;
        } else {
            //Find correct ammo type
            for(i = 0; i < 2; i++) {
                WF = Weapon.GetFireMode(i);
                if(WF != None) {
                    if(WF.IsA('InstantFire')) {
                        if(InstantFire(WF).DamageType == DamageType) {
                            Ammo[i] = WF.AmmoPerFire;
                            break;
                        }
                    } else if(WF.ProjectileClass != None) {
                        if(WF.ProjectileClass.default.MyDamageType == DamageType) {
                            if(
                                DamageType == class'DamTypeFlakChunk' ||
                                DamageType == class'DamTypeFlakShell')
                            {
                                NoAmmoTime = Level.TimeSeconds + 0.75 * (WF.FireRate / Level.TimeDilation);
                            }
                        
                            Ammo[i] = WF.AmmoPerFire;
                            break;
                        }
                    }
                }
            }
            
            //Refund at least one primary ammo
            if(Ammo[0] == 0 && Ammo[1] == 0) {
                Ammo[0] = 1;
            }
        }
        
        //Give ammo
        for(i = 0; i < 2; i++) {
            if(Ammo[i] > 0) {
                Weapon.AddAmmo(Ammo[i], i);
            }
        }
    }
}

function int GetMaxHealthBonus() {
	local Ability_Medic LM;

	if(RPRI != None)
	{
		LM = Ability_Medic(RPRI.GetOwnedAbility(class'Ability_Medic'));
		if(LM != None)
			return LM.GetHealMax();
	}
	
	return Super.GetMaxHealthBonus();
}

simulated function BuildDescription() {
	Super.BuildDescription();
	//AddToDescription(class'WeaponModifier_Infinity'.default.InfAmmoText);
}

defaultproperties {
	HealText="$1 healing, ammo refund"
	bOmitModifierInName=True

	bAllowForSpecials=False
	bCanThrow=False

	MinModifier=5
	MaxModifier=5
	AIRatingBonus=0.100000
	//PatternPos="Medic $W of Infinity"
	PatternPos="Medic $W"
}
