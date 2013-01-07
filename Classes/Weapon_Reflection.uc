class Weapon_Reflection extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float BaseChance;

var localized string ReflectionText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority && bNetDirty)
		BaseChance;
}

function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier)
{
	local RPGEffect Reflected;

	if(EffectClass == class'Effect_NullEntropy')
	{
		if(Causer.Pawn != None && Weapon_Reflection(Causer.Pawn.Weapon) == None)
		{
			Reflected = class'Effect_NullEntropy'.static.Create(Causer.Pawn, Instigator.Controller, Duration, Modifier);
			if(Reflected != None)
				Reflected.Start();
		}
		return false;
	}
	return true;
}

function bool CheckReflect(Vector HitLocation, out Vector RefNormal, int Damage )
{
	//make the call first in case the weapon actually does the reflect on it's own.
	if(Super.CheckReflect(HitLocation, RefNormal, Damage))
		return true;

	if(Damage > 0)
	{
		RefNormal=normal(HitLocation-Location);
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
	CountersMagic(0)=class'Weapon_NullEntropy'
	CountersDamage(0)=class'DamTypeShockBeam'
	CountersDamage(1)=class'DamTypeShockBall'
	CountersDamage(2)=class'DamTypeLinkPlasma'
}
