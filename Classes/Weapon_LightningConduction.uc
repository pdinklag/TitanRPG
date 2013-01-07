class Weapon_LightningConduction extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string LCText;

function RPGAdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	if(DamageType == class'DamTypeSniperShot' ||
		DamageType == class'DamTypeSniperHeadShot' ||
		DamageType == class'DamTypeLightningRod')
	{
		Identify();
		Damage = Max(Damage * (1 - BonusPerLevel * Modifier), 0);
	}

	Super.RPGAdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(LCText, "$1", GetBonusPercentageString(BonusPerLevel));
	return text;
}

defaultproperties
{
	LCText="$1 lightning dmg reduction"
	DamageBonus=0.040000
	BonusPerLevel=0.100000
	MinModifier=1
	MaxModifier=7
	ModifierOverlay=FinalBlend'AW-Shaders.Shaders.AW-LightskinFinal' //< my initial arbitrary choice, and still the best one
	PatternPos="$W of Lightning Conduction"
	//AI
	AIRatingBonus=0.000000
	CountersDamage(0)=class'DamTypeSniperShot'
	CountersDamage(1)=class'DamTypeSniperHeadShot'
	CountersDamage(2)=class'DamTypeLightningRod'
}
