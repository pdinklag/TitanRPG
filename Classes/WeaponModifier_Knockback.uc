class WeaponModifier_Knockback extends RPGWeaponModifier;

var localized string KnockbackText;

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Effect_Knockback Knockback;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
	
	if(Damage > 0)
	{
		Knockback = Effect_Knockback(
			class'Effect_Knockback'.static.Create(Injured, InstigatedBy.Controller, 1.00));
		
		if(Knockback != None)
		{
			Identify();
		
			if
			(
				(Momentum.X == 0 && Momentum.Y == 0 && Momentum.Z == 0) || 
				DamageType == class'DamTypeSniperShot' || 
				DamageType == class'DamTypeClassicSniper' ||
				DamageType == class'DamTypeLinkShaft' ||
				DamageType == class'DamTypeONSAVRiLRocket'
			)
			{
				if(InstigatedBy == Injured)
					Momentum = InstigatedBy.Location - HitLocation;
				else
					Momentum = InstigatedBy.Location - Injured.Location;

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

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(KnockbackText);
}

defaultproperties
{
	DamageBonus=0.04
	BonusPerLevel=0.50
	KnockbackText="knocks targets away"
	MinModifier=2
	MaxModifier=6
	ModifierOverlay=Shader'TitanRPG.Overlays.RedShader'
	PatternPos="$W of Knockback"
	//AI
	AIRatingBonus=0
}
