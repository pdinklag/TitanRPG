class WeaponNullEntropy extends RPGWeapon
	HideDropDown
	CacheExempt;
	
var localized string NullEntropyText;

static function bool CanBeNulled(Pawn P)
{
	if(P == None || Vehicle(P) != None || !class'WeaponFreeze'.static.canTriggerPhysics(P))
		return false;
	
	if(WeaponMagicNullifier(P.Weapon) != None)
		return false;

	if(P.FindInventoryType(class'NullEntropyInv') != None)
		return false;
		
	return true;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local NullEntropyInv Inv;	

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	

	if(Damage > 0)
	{
		if(Instigator == None)
			return;
			
		if(Victim == None || Vehicle(Victim) != None || WeaponMagicNullifier(Victim.Weapon) != None)
			return;
		
		if(!CanBeNulled(Victim))
			return;

		Identify();

		Inv = Spawn(class'NullEntropyInv', Victim,,, rot(0,0,0));
		Inv.LifeSpan = BonusPerLevel * float(Modifier);
		Inv.Modifier = Modifier;
		
		if(WeaponReflection(Victim.Weapon) != None)
		{
			Inv.GiveTo(Instigator);
		}
		else
		{
			Inv.GiveTo(Victim);
		}
		
		Momentum = vect(0, 0, 0);
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= NullEntropyText;
	
	return text;
}

defaultproperties
{
	//bAddToOldWeapons=False
	NullEntropyText="immobilizes human targets"
	DamageBonus=0.050000
	BonusPerLevel=1.000000
	MinModifier=3
	MaxModifier=6
	ModifierOverlay=Shader'MutantSkins.Shaders.MutantGlowShader'
	PatternPos="Null Entropy $W"
	//AI
	AIRatingBonus=0.075000
}
