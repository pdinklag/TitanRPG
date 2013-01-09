class WeaponModifier_Vampire extends RPGWeaponModifier;

var config float VampireMaxHealth;

var localized string VampireText, EmoText;

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
    local float x;

    if(class'DevoidEffect_Vampire'.static.CanBeApplied(Injured, Instigator.Controller)) {
        x = FMax(0, FMin(Injured.Health, float(Damage) * BonusPerLevel * float(Modifier)));
    
        if(Modifier > 0) {
            Identify();
            Instigator.GiveHealth(Max(1, int(x)), Instigator.HealthMax * VampireMaxHealth);
        } else if(Modifier < 0) {
            Identify();
            Instigator.TakeDamage(Max(1, int(-x)), Instigator, Instigator.Location, vect(0, 0, 0), class'DamTypeEmo');
        }
    }
}

simulated function BuildDescription() {
	Super.BuildDescription();
    
    Log("Modifier =" @ Modifier);
    if(Modifier >= 0) {
        AddToDescription(VampireText, BonusPerLevel);
    } else {
        AddToDescription(EmoText, BonusPerLevel);
    }
}

defaultproperties
{
	VampireText="$1 self-healing for dmg"
	EmoText="$1 self-damage"
	DamageBonus=0.04
	BonusPerLevel=0.0375 //VampireAmount * 0.05
	VampireMaxHealth=1.333333 //the good old 33%
	MinModifier=-6
	MaxModifier=8
    bCanHaveZeroModifier=False
	ModifierOverlay=Shader'WeaponSkins.ShockLaser.LaserShader'
	PatternPos="Vampiric $W"
	PatternNeg="$W of Emo"
	//AI
	AIRatingBonus=0.075
}
