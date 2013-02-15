class WeaponModifier_Nullification extends RPGWeaponModifier;
	
var localized string MagicNullText;

var config array<class<RPGEffect> > DenyEffects;

function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier) {
    if(class'Util'.static.InArray(EffectClass, DenyEffects) >= 0) {
        Identify();
        return false;
    }

    return true;
}

simulated function BuildDescription() {
    Super.BuildDescription();
    AddToDescription(MagicNullText);
}

defaultproperties {
    MagicNullText="nullifies harmful effects"
    bCanHaveZeroModifier=True
    DamageBonus=0.050000
    MinModifier=4
    MaxModifier=6
    ModifierOverlay=Shader'AW-2k4XP.Weapons.ShockShieldShader'
    PatternPos="Nullifying $W"
    //Block effects
    DenyEffects(0)=class'DevoidEffect_Matrix'
    DenyEffects(1)=class'DevoidEffect_Vampire'
    DenyEffects(2)=class'Effect_Disco'
    DenyEffects(3)=class'Effect_Freeze'
    DenyEffects(4)=class'Effect_Knockback'
    DenyEffects(5)=class'Effect_NullEntropy'
    DenyEffects(6)=class'Effect_Poison'
    DenyEffects(7)=class'Effect_Vorpal'
    //AI
    CountersModifier(0)=class'WeaponModifier_Freeze'
    CountersModifier(1)=class'WeaponModifier_NullEntropy'
    CountersModifier(2)=class'WeaponModifier_Poison'
    CountersModifier(3)=class'WeaponModifier_Knockback'
    CountersModifier(4)=class'WeaponModifier_Party'
    AIRatingBonus=0.025
}
