class WeaponModifier_Spam extends WeaponModifier_Infinity;

var localized string SpamText;

var float FireRateModifier;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientAdjustFireRate;
}

simulated function ClientAdjustFireRate(float Scale)
{
	if(Role < ROLE_Authority) {
		class'Util'.static.AdjustWeaponFireRate(Weapon, Scale);
    }
}

function StartEffect()
{
	Super.StartEffect();
	
	FireRateModifier = 1.0f + BonusPerLevel * Abs(float(Modifier));
	
	if(Modifier < 0)
		FireRateModifier = 1.0f / FireRateModifier;
	
	class'Util'.static.AdjustWeaponFireRate(Weapon, FireRateModifier);
	ClientAdjustFireRate(FireRateModifier);
}

function StopEffect()
{
	if(Weapon == None)
		return;

	if(FireRateModifier != 0)
	{
		class'Util'.static.AdjustWeaponFireRate(Weapon, 1.0f / FireRateModifier);
		ClientAdjustFireRate(1.0f / FireRateModifier);
	}
	
	FireRateModifier = 0;
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(SpamText, BonusPerLevel);
}

defaultproperties
{
	SpamText="$1 fire rate"
	DamageBonus=0.000000
	BonusPerLevel=0.050000
	MinModifier=-3
	MaxModifier=5
	ModifierOverlay=FinalBlend'X_AW-Shaders.Shaders.StainAgain' //PARTY =D
	PatternPos="$W of SPAM"
	PatternNeg="$W of FAIL"
	bCanHaveZeroModifier=True
	AIRatingBonus=0.025000
}
