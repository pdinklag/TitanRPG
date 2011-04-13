class WeaponModifier_Speed extends RPGWeaponModifier;

var float SpeedModifier;

function StartEffect()
{
	Log(Self @ "StartEffect");

	SpeedModifier = 1.f + BonusPerLevel * Abs(float(Modifier));
	if(Modifier < 0 && SpeedModifier != 0.f)
		SpeedModifier = 1.0 / SpeedModifier;
	
	class'Util'.static.PawnScaleSpeed(Instigator, SpeedModifier);
}

function StopEffect()
{
	Log(Self @ "StopEffect");

	if(SpeedModifier != 0.f)
		class'Util'.static.PawnScaleSpeed(Instigator, 1.f / SpeedModifier);
	
	SpeedModifier = 0.f;
}

defaultproperties
{
	DamageBonus=0.050000
	BonusPerLevel=0.030000
	MinModifier=-3
	MaxModifier=10
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconBS'
	PatternPos="$W of Quickfoot"
	PatternNeg="$W of Slowfoot"
	//AI
	AIRatingBonus=0.025000
}
