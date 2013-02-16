class WeaponModifier_Damage extends RPGWeaponModifier;

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
	Identify();
}

defaultproperties
{
	DamageBonus=0.10
	MinModifier=-3
	MaxModifier=6
	ModifierOverlay=Combiner'AWGlobal.Shaders.Combiner4'
	PatternPos="$W of Damage"
	PatternNeg="$W of Reduced Damage"
}
