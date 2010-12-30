class WeaponKnockback extends RPGWeapon
	HideDropDown
	CacheExempt;

var Sound KnockbackSound;

var localized string KnockbackText;

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local KnockbackInv Inv;
	local TurretKnockoutInv TInv;
	local Vector newLocation;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();

	if(Damage > 0)
	{
		if(Instigator == None)
			return;

		if(Victim == None)
			return;
		
		if(Victim.IsA('ASTurret'))
		{
			TInv = TurretKnockoutInv(Victim.FindInventoryType(class'TurretKnockoutInv'));
			if(TInv == None)
				TInv = TurretKnockoutInv(class'Util'.static.GiveInventory(Victim, class'TurretKnockoutInv'));
			
			TInv.Start(Modifier);
			return;
		}

		if(Victim.IsA('Vehicle') && Vehicle(Victim).bDefensive)
			return;
		
		if(WeaponMagicNullifier(Victim.Weapon) != None)
			return;

		if(!class'WeaponFreeze'.static.canTriggerPhysics(Victim))
			return;

		if(Victim.FindInventoryType(class'KnockbackInv') != None)
			return;

		Inv = Spawn(class'KnockbackInv', Victim,,, rot(0,0,0));
		Inv.LifeSpan = (MaxModifier + 1) - Modifier;
		Inv.Modifier = Modifier;
		Inv.GiveTo(Victim);

		/*
			if they're not walking, falling, or hovering, 
			the momentum won't affect them correctly, so make them hover.
			this effect will end when the KnockbackInv expires.
		*/
		if(
			Victim.Physics != PHYS_Walking && 
			Victim.Physics != PHYS_Falling &&
			Victim.Physics != PHYS_Hovering)
		{
			Victim.SetPhysics(PHYS_Hovering);
		}

		//I check the x,y, and z to see if this projectile has no momentum (some weapons have none)
		if
		(
			(
				Momentum.X == 0 && 
				Momentum.Y == 0 && 
				Momentum.Z == 0
			) || 
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

		class'SyncOverlayMaterial'.static.Sync(Victim, ModifierOverlay, 1.0, false);
		
		if(PlayerController(Victim.Controller) != None)
		 	PlayerController(Victim.Controller).ReceiveLocalizedMessage(class'KnockbackConditionMessage', 0);
	
		Victim.PlaySound(KnockbackSound,,1.5 * Victim.TransientSoundVolume,,Victim.TransientSoundRadius);
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
