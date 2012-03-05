class WeaponFreeze extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float FreezeMax, FreezeDuration;

var Sound FreezeSound;
var localized string FreezeText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		FreezeMax;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local RPGEffect Effect;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(Damage > 0)
	{
		Effect = class'Effect_Freeze'.static.Create(
			Victim,
			Instigator.Controller,
			Modifier * FreezeDuration,
			1.0f - FMin(BonusPerLevel * Modifier, FreezeMax));
		
		if(Effect != None)
		{
			Identify();
			Effect.Start();
		}
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(FreezeText, "$1",
		class'Util'.static.FormatPercent(FMin(Modifier * BonusPerLevel, FreezeMax)));
	
	return text;
}

defaultproperties
{
	BonusPerLevel=0.15
	FreezeMax=0.90
	FreezeDuration=0.500000
	//bAddToOldWeapons=False
	FreezeText="slows targets down $1"
	FreezeSound=Sound'Slaughtersounds.Machinery.Heavy_End'
	DamageBonus=0.050000
	MinModifier=4
	MaxModifier=6
	ModifierOverlay=Shader'TitanRPG.Overlays.GreyShader'
	PatternPos="Freezing $W"
	//AI
	AIRatingBonus=0.050000
}
