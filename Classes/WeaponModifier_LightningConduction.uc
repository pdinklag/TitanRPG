class WeaponModifier_LightningConduction extends RPGWeaponModifier;

var localized string LCText;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(DamageType == class'DamTypeSniperShot' ||
		DamageType == class'DamTypeSniperHeadShot' ||
		DamageType == class'DamTypeLightningRod' ||
        DamageType == class'DamTypeLightningTotem')
	{
		Identify();
		Damage = Max(Damage * (1 - BonusPerLevel * Modifier), 0);
	}

	Super.AdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
}

simulated function BuildDescription()
{
	Super.BuildDescription();
    AddToDescription(LCText, BonusPerLevel);
}

defaultproperties
{
    LCText="$1 lightning dmg reduction"
	DamageBonus=0.04
	BonusPerLevel=0.10
	MinModifier=2
	MaxModifier=6
	ModifierOverlay=FinalBlend'AW-Shaders.Shaders.AW-LightskinFinal'
	PatternPos="$W of Lightning Conduction"
	//AI
	AIRatingBonus=0
	CountersDamage(0)=class'DamTypeSniperShot'
	CountersDamage(1)=class'DamTypeSniperHeadShot'
	CountersDamage(2)=class'DamTypeLightningRod'
	CountersDamage(3)=class'DamTypeLightningTotem'
}
