class WeaponModifier_InfSturdy extends WeaponModifier_Infinity;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Identify();
	Momentum = vect(0, 0, 0);
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(class'WeaponModifier_Sturdy'.default.SturdyText);
}

defaultproperties
{
	DamageBonus=0.075
	MinModifier=4
	MaxModifier=10
	ModifierOverlay=Combiner'UT2004Weapons.Shaders.Combiner10'
	PatternPos="$W of Infinite Sturdiness"
	bCanHaveZeroModifier=True
	//AI
	AIRatingBonus=0.10
	CountersModifier(0)=class'WeaponModifier_Knockback'
	CountersDamage(0)=class'DamTypeCounterShove'
}
