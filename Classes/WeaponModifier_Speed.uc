class WeaponModifier_Speed extends RPGWeaponModifier;

var float SpeedModifier;

var localized string SpeedText;

function StartEffect()
{
	SpeedModifier = 1.0f + BonusPerLevel * Abs(float(Modifier));
	if(Modifier < 0 && SpeedModifier != 0)
		SpeedModifier = 1.0 / SpeedModifier;
	
	class'Util'.static.PawnScaleSpeed(Instigator, SpeedModifier);
	
	Identify();
}

function StopEffect()
{
	if(SpeedModifier != 0)
		class'Util'.static.PawnScaleSpeed(Instigator, 1.0f / SpeedModifier);

	SpeedModifier = 0;
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(SpeedText, BonusPerLevel);
}

defaultproperties
{
	SpeedText="$1 movement speed"
	DamageBonus=0.050000
	BonusPerLevel=0.030000
	MinModifier=-3
	MaxModifier=7
    bCanHaveZeroModifier=False
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconBS'
	PatternPos="$W of Speed"
	PatternNeg="$W of Slowness"
	//AI
	AIRatingBonus=0.025
}
