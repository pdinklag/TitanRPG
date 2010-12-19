class WeaponSturdy extends RPGWeapon
	HideDropDown
	CacheExempt;
	
var localized string SturdinessText;

function RPGAdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	Super.RPGAdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
	
	Identify();
	Momentum = vect(0, 0, 0);
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= SturdinessText;
	return text;
}

defaultproperties
{
	SturdinessText="sturdiness"
	bCanHaveZeroModifier=True
	DamageBonus=0.040000
	MinModifier=-2
	MaxModifier=6
	ModifierOverlay=Shader'UT2004Weapons.Shaders.ShockHitShader'
	PatternPos="Sturdy $W"
	PatternNeg="Sturdy $W"
	//AI
	AIRatingBonus=0.012500
	CountersMagic(0)=class'WeaponKnockback'
	CountersDamage(0)=class'DamTypeCounterShove'
}
