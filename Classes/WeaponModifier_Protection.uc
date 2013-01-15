class WeaponModifier_Protection extends RPGWeaponModifier;

var config int HealthCap;
var config float ProtectionDuration;

var localized string DRText;
var localized string ProtectionText;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
    local RPGEffect Prot;

	Super.AdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
	
	Damage = Max(Damage * (1 - BonusPerLevel * Modifier), 0);
	Identify();

	if(Modifier > 0 && Damage >= Instigator.Health && Instigator.Health > HealthCap) {
        Prot = class'Effect_Protection'.static.Create(Instigator, None, ProtectionDuration / float(Modifier));
        if(Prot != None) {
            Prot.Start();
        
            Instigator.Health = 1;
            Damage = 0;
        }
	}
}

simulated function BuildDescription() {
    Super.BuildDescription();
    
    AddToDescription(DRText, BonusPerLevel);
    AddToDescription(ProtectionText);
}

defaultproperties
{
	DRText="$1 dmg reduction"
	ProtectionText="Ultima & death protection"
	DamageBonus=0.025
	BonusPerLevel=0.05
	HealthCap=10
	ProtectionDuration=6.00
	MinModifier=1
	MaxModifier=5
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.PlayerShieldSh'
	PatternPos="$W of Protection"
	PatternNeg="$W of Harm"
	//AI
	AIRatingBonus=0.05
}
