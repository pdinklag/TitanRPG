class WeaponMagicNullifier extends RPGWeapon
	HideDropDown
	CacheExempt;
	
var localized string MagicNullText;

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= MagicNullText;
	
	return text;
}

function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Modifier)
{
	return !EffectClass.default.bHarmful; //don't allow harmful effects
}

defaultproperties
{
	MagicNullText="nullifies harmful magic weapon effects"
	bCanHaveZeroModifier=True
	DamageBonus=0.050000
	MinModifier=4
	MaxModifier=6
	ModifierOverlay=Shader'AW-2k4XP.Weapons.ShockShieldShader'
	PatternPos="Magic Nullifying $W"
	//AI
	CountersMagic(0)=class'WeaponFreeze'
	CountersMagic(1)=class'WeaponNullEntropy'
	CountersMagic(2)=class'WeaponPoison'
	CountersMagic(3)=class'WeaponKnockback'
	AIRatingBonus=0.025000
}
