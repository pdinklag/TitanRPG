class WeaponModifier_Piercing extends RPGWeaponModifier;

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

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local float Old;
	
	Old = DamageBonus;
	
	if(Injured.IsA('Vehicle'))
	{
		Identify();
		DamageBonus = BonusPerLevel;
	}

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
	
	DamageBonus = Old;
	
    //TODO effect system
	if(class'WeaponModifier_Nullification'.static.GetFor(Injured.Weapon) != None)
		return;
	
	if(Injured.ShieldStrength > 0 && DamageType.default.bArmorStops)
	{
		Identify();

		DamageType.default.bArmorStops = false;
		ModifiedDamageType = DamageType;
	}
}

function RPGTick(float dt)
{
	if(ModifiedDamageType != None)
	{
		ModifiedDamageType.default.bArmorStops = true;
		ModifiedDamageType = None;
	}

	Super.RPGTick(dt);
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(PiercingText, BonusPerLevel);
}

defaultproperties
{
	PiercingText="pierces shield, $1 dmg bonus against vehicles"
	DamageBonus=0.05
	BonusPerLevel=0.10
	MinModifier=1
	MaxModifier=8
	ModifierOverlay=Shader'UT2004Weapons.Shaders.BlueShockFall'
	PatternPos="Piercing $W"
	//AI
	AIRatingBonus=0.025
}
