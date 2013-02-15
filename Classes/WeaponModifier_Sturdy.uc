class WeaponModifier_Sturdy extends RPGWeaponModifier;

var localized string SturdyText;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Identify();
	Momentum = vect(0, 0, 0);
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(SturdyText);
}

defaultproperties
{
	SturdyText="sturdiness"
	bCanHaveZeroModifier=True
	DamageBonus=0.040000
	MinModifier=-2
	MaxModifier=6
	ModifierOverlay=Shader'UT2004Weapons.Shaders.ShockHitShader'
	PatternPos="Sturdy $W"
	PatternNeg="Sturdy $W"
	//AI
	AIRatingBonus=0.012500
	CountersModifier(0)=class'WeaponModifier_Knockback'
	CountersDamage(0)=class'DamTypeCounterShove'
}
