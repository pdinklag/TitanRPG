class Weapon_Damage extends RPGWeapon
	HideDropDown
	CacheExempt;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();
}

defaultproperties
{
	DamageBonus=0.100000
	MinModifier=1
	MaxModifier=6
	ModifierOverlay=Combiner'AWGlobal.Shaders.Combiner4'
	PatternPos="$W of Damage"
	PatternNeg="$W of Reduced Damage"
	//AI
	AIRatingBonus=0.000000
}
