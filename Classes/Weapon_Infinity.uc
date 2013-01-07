class Weapon_Infinity extends RPGWeapon
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
	//AI
	AIRatingBonus=0.025000
}
