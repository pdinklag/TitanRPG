class WeaponKnockback extends RPGWeapon
	HideDropDown
	CacheExempt;

var Sound KnockbackSound;

var localized string KnockbackText;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Vector newLocation;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();

	if(Damage > 0)
	{
		if(class'EffectKnockback'.static.Apply(Victim, Instigator.Controller, (MaxModifier + 1) - Modifier) != None)
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

				Momentum = Normal(Momentum);
				Momentum *= -200;

				/*
					if they're walking, I need to bump them up 
					in the air a bit or they won't be knocked back 
					on no momentum weapons.
				*/
				if(Victim.Physics == PHYS_Walking)
				{
					newLocation = Victim.Location;
					newLocation.z += 10;
					Victim.SetLocation(newLocation);
				}
			}

			Momentum *= FMax(2.0, FMax(float(Modifier) * BonusPerLevel, float(Damage) * 0.1)); //kawham!
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
