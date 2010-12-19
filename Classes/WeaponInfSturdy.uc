class WeaponInfSturdy extends WeaponInfinity
	HideDropDown
	CacheExempt;

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
	
	text $= class'WeaponSturdy'.default.SturdinessText;
	return text;
}

defaultproperties
{
	//bAddToOldWeapons=False
	DamageBonus=0.075000
	MinModifier=4
	MaxModifier=10
	ModifierOverlay=Combiner'UT2004Weapons.Shaders.Combiner10'
	PatternPos="$W of Infinite Sturdiness"
	bCanHaveZeroModifier=True
	ForbiddenWeaponTypes(0)=Class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=Class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(2)=Class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(3)=Class'XWeapons.Painter'
	ForbiddenWeaponTypes(4)=Class'OnslaughtFull.ONSPainter'
	//AI
	AIRatingBonus=0.100000
	CountersMagic(0)=class'WeaponKnockback'
	CountersDamage(0)=class'DamTypeCounterShove'
}
