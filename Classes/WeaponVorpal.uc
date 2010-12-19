class WeaponVorpal extends RPGWeapon
	HideDropDown
	CacheExempt;

var config Sound InstantKillSound;
var config array<class<DamageType> > IgnoreDamageTypes;

var config array<class<Pawn> > Immune;

var localized string VorpalText;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local int Chance;
	local Actor A;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(class'Util'.static.InArray(Victim.class, Immune) >= 0)
		return;

	if(class'Util'.static.InArray(DamageType, IgnoreDamageTypes) >= 0)
		return;

	if(Victim == None || WeaponMagicNullifier(Victim.Weapon) != None)
		return;
		
	Chance = Modifier - MinModifier;
	if(Damage > 0 && Chance >= Rand(99))
	{
		//Instant death
		Identify();
		
		A = Spawn(class'RocketExplosion',,, Instigator.Location);
		if (A != None)
		{
			A.RemoteRole = ROLE_SimulatedProxy;
			A.PlaySound(InstantKillSound,,2.5*Instigator.TransientSoundVolume,,Instigator.TransientSoundRadius);
		}

		Victim.Died(Instigator.Controller, DamageType, Victim.Location);

		A = Spawn(class'RocketExplosion',,, Victim.Location);
		if (A != None)
		{
			A.RemoteRole = ROLE_SimulatedProxy;
			A.PlaySound(InstantKillSound,,2.5*Victim.TransientSoundVolume,,Victim.TransientSoundRadius);
		}
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
	InstantKillSound=Sound'WeaponSounds.Misc.instagib_rifleshot'
	IgnoreDamageTypes(0)=Class'XWeapons.DamTypeRedeemer'
	IgnoreDamageTypes(1)=Class'XWeapons.DamTypeIonBlast'
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
