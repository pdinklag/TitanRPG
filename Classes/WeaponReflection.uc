class WeaponReflection extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float BaseChance;

var localized string ReflectionText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority && bNetDirty)
		BaseChance;
}

function bool CheckReflect(Vector HitLocation, out Vector RefNormal, int Damage )
{
	//make the call first in case the weapon actually does the reflect on it's own.
	if(Super.CheckReflect(HitLocation, RefNormal, Damage))
		return true;

	if(Damage > 0)
	{
		RefNormal=normal(HitLocation-Location);
		//if(Rand(99) < int((Growth ** float(Modifier)) * BaseChance))
		if(FRand() < (BaseChance + float(Modifier) * BonusPerLevel))
		{
			Identify();
		
			class'Sync_OverlayMaterial'.static.Sync(Instigator, ModifierOverlay, 1.0, false);
			return true;
		}
	}
	return false;
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(ReflectionText, "$1", class'Util'.static.FormatPercent(BaseChance + float(Modifier) * BonusPerLevel));
	return text;
}

defaultproperties
{
	ReflectionText="$1 reflection chance"
	DamageBonus=0.05
	BaseChance=0.25
	BonusPerLevel=0.10
	MinModifier=1
	MaxModifier=7
	//ModifierOverlay=Shader'AWGlobal.Shaders.WetBlood01aw'
	ModifierOverlay=TexEnvMap'VMVehicles-TX.Environments.ReflectionEnv'
	PatternPos="Reflecting $W"
	bCanHaveZeroModifier=True
	//AI
	AIRatingBonus=0.025000
	CountersMagic(0)=class'WeaponNullEntropy'
	CountersDamage(0)=class'DamTypeShockBeam'
	CountersDamage(1)=class'DamTypeShockBall'
	CountersDamage(2)=class'DamTypeLinkPlasma'
}
