class WeaponKnockback extends RPGWeapon
	HideDropDown
	CacheExempt;

var Sound KnockbackSound;

var localized string KnockbackText;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local EffectKnockback Knockback;
	local vector KBMomentum;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();

	if(Damage > 0)
	{
		Knockback = EffectKnockback(
			class'EffectKnockback'.static.Create(Victim, Instigator.Controller, (MaxModifier + 1) - Modifier));
		
		if(Knockback != None)
		{
			KBMomentum = Momentum;
			Momentum = vect(0, 0, 0); //Knockback effect will handle it
		
			if
			(
				(Momentum.X == 0 && Momentum.Y == 0 && Momentum.Z == 0) || 
				DamageType == class'DamTypeSniperShot' || 
				DamageType == class'DamTypeClassicSniper' ||
				DamageType == class'DamTypeLinkShaft' ||
				DamageType == class'DamTypeONSAVRiLRocket'
			)
			{
				if(Instigator == Victim)
					KBMomentum = Instigator.Location - HitLocation;
				else
					KBMomentum = Instigator.Location - Victim.Location;

				KBMomentum = Normal(KBMomentum);
				KBMomentum *= -200;
			}

			KBMomentum *= FMax(2.0, FMax(float(Modifier) * BonusPerLevel, float(Damage) * 0.1)); //kawham!
			Knockback.Momentum = KBMomentum;
			Knockback.Start();
		}
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= KnockbackText;
	return text;
}

defaultproperties
{
	KnockbackText="knocks targets away"
	KnockbackSound=Sound'WeaponSounds.Misc.ballgun_launch'
	DamageBonus=0.040000
	BonusPerLevel=0.500000
	MinModifier=2
	MaxModifier=6
	ModifierOverlay=Shader'<? echo($packageName); ?>.Overlays.RedShader'
	PatternPos="$W of Knockback"
	//AI
	AIRatingBonus=0.000000
}
