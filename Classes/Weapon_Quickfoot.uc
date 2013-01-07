class Weapon_Quickfoot extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string QFText;

var float SpeedModifier;

function StartEffect()
{
	Identify();

	SpeedModifier = 1.f + BonusPerLevel * Abs(float(Modifier));
	if(Modifier < 0 && SpeedModifier != 0.f)
		SpeedModifier = 1.0 / SpeedModifier;
	
	class'Util'.static.PawnScaleSpeed(Instigator, SpeedModifier);
}

function StopEffect()
{
	if(SpeedModifier != 0.f)
		class'Util'.static.PawnScaleSpeed(Instigator, 1.f / SpeedModifier);
	
	SpeedModifier = 0.f;
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= GetBonusPercentageString(BonusPerLevel) @ QFText;
	return text;
}

defaultproperties
{
	QFText="movement speed"
	//bAddToOldWeapons=False
	DamageBonus=0.050000
	BonusPerLevel=0.030000
	MinModifier=-3
	MaxModifier=7
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconBS'
	PatternPos="$W of Quickfoot"
	PatternNeg="$W of Slowfoot"
	//AI
	AIRatingBonus=0.025000
}
