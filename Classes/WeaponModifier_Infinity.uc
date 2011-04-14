class WeaponModifier_Infinity extends RPGWeaponModifier;

var localized string InfAmmoText;

function RPGTick(float dt)
{
	Weapon.MaxOutAmmo();
}

simulated function string GetDescription()
{
	local string text;
	
	text = Super.GetDescription();
	
	if(text != "")
		text $= ", ";
	
	text $= InfAmmoText;
	return text;
}

defaultproperties
{
	bAllowForSpecials=False

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
	