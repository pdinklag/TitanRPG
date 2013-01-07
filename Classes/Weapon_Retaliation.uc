class Weapon_Retaliation extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string RetalText;

function RPGAdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local int RetalDamage;

	Super.RPGAdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
	Identify();

	if(DamageType == class'DamTypeCounterShove' || DamageType == class'DamTypeRetaliation')
		return;
		
	if(Weapon_MagicNullifier(InstigatedBy.Weapon) != None)
		return;

	if(InstigatedBy != None && InstigatedBy != Instigator && !InstigatedBy.Controller.SameTeamAs(Instigator.Controller))
	{
		RetalDamage = int(float(Modifier) * BonusPerLevel * float(Damage));
		RetalDamage = FMin(RetalDamage, float(Instigator.Health));
		
		if(RetalDamage > 0)
		{
			InstigatedBy.TakeDamage(
				RetalDamage,
				Instigator,
				InstigatedBy.Location,
				vect(0, 0, 0),
				class'DamTypeRetaliation');
		}
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(RetalText, "$1", GetBonusPercentageString(BonusPerLevel));
		
	return text;
}

defaultproperties
{
	RetalText="$1 dmg return"
	DamageBonus=0.040000
	BonusPerLevel=0.05
	MinModifier=1
	MaxModifier=8
	ModifierOverlay=Shader'UT2004Weapons.Shaders.RedShockFall'
	PatternPos="$W of Retaliation"
	//AI
	AIRatingBonus=0.025000
	/*
		This weapon type doesn't actually counter these damage types, but since
		they usually mean a lot of damage, it is advantageous to pick this.
	*/
	CountersDamage(0)=class'DamTypeONSMine'
	CountersDamage(1)=class'DamTypeONSGrenade'
	CountersDamage(2)=class'DamTypeRocket'
	CountersDamage(3)=class'DamTypeRocketHoming'
	CountersDamage(4)=class'DamTypeFlakShell'
}
