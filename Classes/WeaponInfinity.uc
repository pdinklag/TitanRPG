class WeaponInfinity extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string InfAmmoText;

function bool ConsumeAmmo(int Mode, float Load, bool bAmountNeededIsMax)
{
	Identify();
	return true;
}

simulated function WeaponTick(float dt)
{
	MaxOutAmmo();
	Super.WeaponTick(dt);
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= InfAmmoText;
	return text;
}

defaultproperties
{
	InfAmmoText="infinite ammo"
	DamageBonus=0.050000
	MinModifier=-3
	MaxModifier=8
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconRS'
	PatternPos="$W of Infinity"
	PatternNeg="$W of Infinity"
	bCanHaveZeroModifier=True
	ForbiddenWeaponTypes(0)=Class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=Class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(2)=Class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(3)=Class'XWeapons.Painter'
	ForbiddenWeaponTypes(4)=Class'OnslaughtFull.ONSPainter'
	//AI
	AIRatingBonus=0.025000
}
