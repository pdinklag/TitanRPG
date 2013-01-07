class Weapon_Feather extends RPGWeapon
	CacheExempt
	HideDropDown;

var config float JumpZBonus, MaxFallSpeedBonus;
var float JumpZModifier, MaxFallSpeedModifier;

var localized string FeatherText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		JumpZBonus, MaxFallSpeedBonus;
}

function StartEffect()
{
	Identify();

	JumpZModifier = 1.f + JumpZBonus * Abs(float(Modifier));
	if(Modifier < 0 && JumpZModifier != 0.f)
		JumpZModifier = 1.0 / JumpZModifier;
	
	MaxFallSpeedModifier = 1.f + MaxFallSpeedBonus * Abs(float(Modifier));
	if(Modifier < 0 && MaxFallSpeedModifier != 0.f)
		MaxFallSpeedModifier = 1.0 / MaxFallSpeedModifier;
	
	Instigator.JumpZ *= JumpZModifier;
	Instigator.MaxFallSpeed *= MaxFallSpeedModifier;
}

function StopEffect()
{
	if(JumpZModifier != 0.f)
		Instigator.JumpZ /= JumpZModifier;
		
	if(MaxFallSpeedModifier != 0.f)
		Instigator.MaxFallSpeed /= MaxFallSpeedModifier;
	
	JumpZModifier = 0.f;
	MaxFallSpeedModifier = 0.f;
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(
		Repl(FeatherText, "$1", GetBonusPercentageString(JumpZBonus)),
		"$2", GetBonusPercentageString(-MaxFallSpeedBonus));
		
	return text;
}

defaultproperties
{
	FeatherText="$1 jump height, $2 fall dmg"
	//bAddToOldWeapons=False
	DamageBonus=0.040000
	JumpZBonus=0.050000
	MaxFallSpeedBonus=0.030000
	MinModifier=-3
	MaxModifier=10
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconBS'
	PatternPos="$W of Feather"
	PatternNeg="$W of Burden"
	//AI
	AIRatingBonus=0.000000
}
