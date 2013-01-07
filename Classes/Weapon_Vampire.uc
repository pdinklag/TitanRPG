class Weapon_Vampire extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float VampireMaxHealth;

var localized string VampireText, EmoText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		VampireMaxHealth;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local float x;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(Victim == None || Victim == Instigator)
		return;

	if(Victim.IsA('Vehicle') && Vehicle(Victim).IsVehicleEmpty())
		return;

	if(
		Damage <= 0 ||
		Victim.Health <= 0 ||
		Weapon_MagicNullifier(Victim.Weapon) != None
	)
	{
		return;
	}
	
	Identify();
	
	x = FMax(0, FMin(Victim.Health, float(Damage) * BonusPerLevel * float(Modifier)));
	
	if(Modifier > 0)
		Instigator.GiveHealth(Max(1, int(x)), Instigator.HealthMax * VampireMaxHealth);
	else if(Modifier < 0)
		Instigator.TakeDamage(Max(1, int(-x)), Instigator, Instigator.Location, vect(0, 0, 0), class'DamTypeEmo');
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	if(Modifier < 0)
		text $= Repl(EmoText, "$1", GetBonusPercentageString(BonusPerLevel));
	else
		text $= Repl(VampireText, "$1", GetBonusPercentageString(BonusPerLevel));
		
	return text;
}

defaultproperties
{
	VampireText="$1 self-healing for dmg"
	EmoText="$1 self-damage"
	DamageBonus=0.040000
	BonusPerLevel=0.0375 //VampireAmount * 0.05
	VampireMaxHealth=1.333333 //the good old 33%
	MinModifier=-6
	MaxModifier=8
	ModifierOverlay=Shader'WeaponSkins.ShockLaser.LaserShader'
	PatternPos="Vampiric $W"
	PatternNeg="$W of Emo"
	//AI
	AIRatingBonus=0.075000
}
