class WeaponVorpal extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string VorpalText;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local RPGEffect Vorpal;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(Damage > 0 && Rand(99) <= (Modifier - MinModifier))
	{
		Identify();
	
		Vorpal = class'EffectVorpal'.static.Create(Victim, Instigator.Controller);
		if(Vorpal != None)
			Vorpal.Start();
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= VorpalText;
	return text;
}

defaultproperties
{
	VorpalText="instant kill chance"
	DamageBonus=0.100000
	MinModifier=6
	MaxModifier=10
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconYS'
	PatternPos="Vorpal $W"
	ForbiddenWeaponTypes(0)=Class'XWeapons.AssaultRifle'
	ForbiddenWeaponTypes(1)=Class'XWeapons.FlakCannon'
	ForbiddenWeaponTypes(2)=Class'XWeapons.LinkGun'
	ForbiddenWeaponTypes(3)=Class'XWeapons.Minigun'
	//AI
	AIRatingBonus=0.100000
}
