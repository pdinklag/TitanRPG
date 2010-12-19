class WeaponSpam extends WeaponInfinity
	HideDropDown
	CacheExempt;

var localized string SpamText;

function SetModifier(int NewModifier)
{
	Super.SetModifier(NewModifier);
	SetWeaponSpeed();
}

//just introduced and already good use for it :3
function SetWeaponSpeed()
{
	local RPGPlayerReplicationInfo RPRI;

	if(Role == ROLE_Authority)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
			SetFireRateScale(1.0f + 0.01f * RPRI.WeaponSpeed + BonusPerLevel * Modifier);
		else
			SetFireRateScale(1.0f);
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(SpamText, "$1", GetBonusPercentageString(BonusPerLevel));
	return text;
}

defaultproperties
{
	SpamText="$1 fire rate"
	DamageBonus=0.000000
	BonusPerLevel=0.050000
	MinModifier=1
	MaxModifier=5
	ModifierOverlay=FinalBlend'X_AW-Shaders.Shaders.StainAgain' //PARTY =D
	PatternPos="$W of SPAM"
	PatternNeg="$W of FAIL"
	bCanHaveZeroModifier=True
	ForbiddenWeaponTypes(0)=Class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=Class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(2)=Class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(3)=Class'XWeapons.Painter'
	ForbiddenWeaponTypes(4)=Class'OnslaughtFull.ONSPainter'
	AIRatingBonus=0.025000
}
