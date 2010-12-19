class WeaponPiercing extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string PiercingText;

var class<DamageType> ModifiedDamageType;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();
	
	if(WeaponMagicNullifier(Victim.Weapon) != None)
		return;

	if(Victim.ShieldStrength > 0 && DamageType.default.bArmorStops)
	{
		if(!bIdentified)
			Identify();
			
		DamageType.default.bArmorStops = false;
		ModifiedDamageType = DamageType;
	}
}

simulated function WeaponTick(float dt)
{
	if(ModifiedDamageType != None)
	{
		ModifiedDamageType.default.bArmorStops = true;
		ModifiedDamageType = None;
	}

	Super.WeaponTick(dt);
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= PiercingText;
	return text;
}

defaultproperties
{
	PiercingText="pierces shield"
	bCanHaveZeroModifier=True
	DamageBonus=0.050000
	MinModifier=-3
	MaxModifier=8
	ModifierOverlay=Shader'UT2004Weapons.Shaders.BlueShockFall'
	PatternPos="Piercing $W"
	PatternNeg="Piercing $W"
	//AI
	AIRatingBonus=0.025000
}
