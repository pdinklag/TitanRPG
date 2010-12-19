class WeaponArmorPiercing extends RPGWeapon
	HideDropDown
	CacheExempt;

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

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(Vehicle(Victim) != None)
	{
		Identify();
		Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	}
}

defaultproperties
{
	DamageBonusText="$1 damage against vehicles"
	DamageBonus=0.100000
	MinModifier=1
	MaxModifier=6
	ModifierOverlay=TexPanner'AWGlobal.Shaders.TexPanner8'
	PatternPos="Armor Piercing $W"
	//AI
	AIRatingBonus=0.000000
}
