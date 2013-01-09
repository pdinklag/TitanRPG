class WeaponModifier_Shield extends RPGWeaponModifier;

var config float RegenInterval;

var localized string ShieldText;

var float RegenTime;

function RestartRegenTimer() {
    RegenTime = Level.TimeSeconds + RegenInterval;
}

function StartEffect() {
    RestartRegenTimer();
}

function RPGTick(float dt) {
    local xPawn x;
	x = xPawn(Instigator);

    if(x != None && Level.TimeSeconds >= RegenTime) {
		if(x.ShieldStrength < x.ShieldStrengthMax)
			x.ShieldStrength = FMin(x.ShieldStrength + float(Modifier) * BonusPerLevel, x.ShieldStrengthMax);
        
        RestartRegenTimer();
    }
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
    Super.AdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
    
    if(Damage > 0) {
        RestartRegenTimer(); //reset on damage
    }
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(ShieldText);
}

defaultproperties
{
	ShieldText="shield regeneration"
	PatternPos="$W of Shield"
	DamageBonus=0.04
	BonusPerLevel=1.00
	RegenInterval=2.00
	MinModifier=1
	MaxModifier=5
	//ModifierOverlay=TexEnvMap'TitanRPG.Overlays.goldenv' - for another weapon
	ModifierOverlay=TexEnvMap'PickupSkins.Shaders.TexEnvMap2'
	//AI
	AIRatingBonus=0.05
}

