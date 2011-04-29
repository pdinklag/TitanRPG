class WeaponPiercing extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string PiercingText;

var class<DamageType> ModifiedDamageType;

function float GetAIRating()
{
	local Pawn Enemy;
	local float Rating;
	
	Rating = Super.GetAIRating();
	
	Enemy = Instigator.Controller.Enemy;
	if(Enemy != None && (Vehicle(Enemy) != None || Enemy.DrivenVehicle != None))
		Rating *= 2.0; //if fighting against a vehicle, rate this double
	
	return Rating;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local float Old;
	
	Old = DamageBonus;
	
	if(Victim.IsA('Vehicle'))
	{
		Identify();
		DamageBonus = BonusPerLevel;
	}

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	
	DamageBonus = Old;
	
	if(WeaponMagicNullifier(Victim.Weapon) != None)
		return;
	
	if(Victim.ShieldStrength > 0 && DamageType.default.bArmorStops)
	{
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
	PiercingText="pierces shield, extra damage against vehicles"
	bCanHaveZeroModifier=True
	DamageBonus=0.05
	BonusPerLevel=0.10
	MinModifier=-3
	MaxModifier=8
	ModifierOverlay=Shader'UT2004Weapons.Shaders.BlueShockFall'
	PatternPos="Piercing $W"
	PatternNeg="Piercing $W"
	//AI
	AIRatingBonus=0.025000
}
