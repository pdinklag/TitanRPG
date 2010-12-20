class WeaponProtection extends RPGWeapon
	HideDropDown
	CacheExempt;

var config int HealthCap;
var config float ProtectionRepeatLifespan;

var Sound ProtectionSound;
var float ProtectionSoundVol;

var localized string DRText;
var localized string ProtectionText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		HealthCap;
}

function RPGAdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local ProtectionInv Inv;

	Super.RPGAdjustPlayerDamage(Damage, OriginalDamage, InstigatedBy, HitLocation, Momentum, DamageType);
	
	Damage = Max(Damage * (1 - BonusPerLevel * Modifier), 0);
	Identify();

	if(Modifier > 0 && Damage >= Instigator.Health && Instigator.Health > HealthCap)
	{
		Inv = ProtectionInv(Instigator.FindInventoryType(class'ProtectionInv'));
		if(Inv == None)
		{
			Instigator.PlaySound(ProtectionSound,, ProtectionSoundVol * Instigator.TransientSoundVolume,,Instigator.TransientSoundRadius);

			Instigator.Health = 1;
			Damage = 0;

			Inv = Spawn(class'ProtectionInv', Instigator,,, rot(0,0,0));
			Inv.Lifespan = (ProtectionRepeatLifespan / float(Modifier));

			if(Inv != None)
				Inv.giveTo(Instigator);
		}
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(DRText, "$1", GetBonusPercentageString(BonusPerLevel));
	text $= ", ";
	text $= ProtectionText;
	return text;
}

defaultproperties
{
	ProtectionSound=Sound'<? echo($packageName); ?>.SoundEffects.Protection' //Sound'WeaponSounds.Misc.instagib_rifleshot'
	ProtectionSoundVol=6.00
	DRText="$1 dmg reduction"
	ProtectionText="Ultima Shield, instant kill protection"
	DamageBonus=0.025000
	BonusPerLevel=0.050000
	HealthCap=10
	ProtectionRepeatLifespan=6.000000
	MinModifier=1
	MaxModifier=5
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.PlayerShieldSh'
	PatternPos="$W of Protection"
	PatternNeg="$W of Harm"
	//AI
	AIRatingBonus=0.050000
}
