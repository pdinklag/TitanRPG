class WeaponFreeze extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float FreezeMax, FreezeDuration;

var Sound FreezeSound;
var localized string FreezeText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		FreezeMax;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local FreezeInv Inv;
	local Actor A;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(Damage > 0)
	{
		if(Victim == None || Vehicle(Victim) != None || WeaponMagicNullifier(Victim.Weapon) != None)
			return;
		
		if(Victim != None && canTriggerPhysics(Victim))
		{
			Identify();

			Inv = FreezeInv(Victim.FindInventoryType(class'FreezeInv'));
			//dont add to the time a pawn is already frozen. It just wouldn't be fair.
			if(Inv == None)
			{
				Inv = spawn(class'FreezeInv', Victim,,, rot(0,0,0));
				Inv.Modifier = Modifier;
				Inv.LifeSpan = Modifier * FreezeDuration;
				Inv.GiveTo(Victim);

				A = Victim.Spawn(class'IceSmokeEffect', Victim,, Victim.Location, Victim.Rotation);
				A.PlaySound(FreezeSound,,2.5*Victim.TransientSoundVolume,,Victim.TransientSoundRadius);
			}
		}
	}
}

static function bool canTriggerPhysics(Pawn victim)
{
	if(victim == None)
		return true;
		
	if(Victim.PlayerReplicationInfo != None && Victim.PlayerReplicationInfo.HasFlag != None)
		return false;

	return true;
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(FreezeText, "$1",
		class'Util'.static.FormatPercent(FMin(Modifier * BonusPerLevel, FreezeMax)));
	
	return text;
}

defaultproperties
{
	BonusPerLevel=0.15
	FreezeMax=0.90
	FreezeDuration=0.500000
	//bAddToOldWeapons=False
	FreezeText="slows targets down $1"
	FreezeSound=Sound'Slaughtersounds.Machinery.Heavy_End'
	DamageBonus=0.050000
	MinModifier=4
	MaxModifier=6
	ModifierOverlay=Shader'<? echo($packageName); ?>.Overlays.GreyShader'
	PatternPos="Freezing $W"
	//AI
	AIRatingBonus=0.050000
}
