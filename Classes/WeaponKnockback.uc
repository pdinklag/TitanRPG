class WeaponKnockback extends RPGWeapon
	HideDropDown
	CacheExempt;

var Sound KnockbackSound;

var localized string KnockbackText;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Effect_Knockback Knockback;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();

	if(Damage > 0)
	{
		Knockback = Effect_Knockback(
			class'Effect_Knockback'.static.Create(Victim, Instigator.Controller, 1.00));
		
		if(Knockback != None)
		{
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
					Momentum = Instigator.Location - HitLocation;
				else
					Momentum = Instigator.Location - Victim.Location;

				Momentum = Normal(Momentum) * -200;
			}

			Momentum *= FMax(2.0, FMax(float(Modifier) * BonusPerLevel, float(Damage) * 0.1)); //kawham!
			
			/*
				momentum will be applied by the weapon,
				TakeDamage just doesn't work while in a NetDamge subcall
			*/
			Knockback.Momentum = vect(0, 0, 0);
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
	ModifierOverlay=Shader'TitanRPG.Overlays.RedShader'
	PatternPos="$W of Knockback"
	//AI
	AIRatingBonus=0.000000
}
