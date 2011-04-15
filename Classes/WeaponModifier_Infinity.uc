class WeaponModifier_Infinity extends RPGWeaponModifier;

var localized string InfAmmoText;

function WeaponFire(byte Mode)
{
	Identify();
}

function RPGTick(float dt)
{
	//TODO: Find a way for ballistic weapons
	Weapon.MaxOutAmmo();
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(InfAmmoText);
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
