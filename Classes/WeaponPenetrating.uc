class WeaponPenetrating extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string PenetratingText;

var int Recursions;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	
	if(!Super.AllowedFor(Weapon, Other))
		return false;

	for (x = 0; x < NUM_FIRE_MODES; x++)
	{
		if (class<InstantFire>(Weapon.default.FireModeClass[x]) != None)
			return true;
	}

	return false;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local int i;
	local vector X, Y, Z, StartTrace;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	Identify();
	
	if(Recursions >= 10)
	{
		Log(Self @ "More than 10 recursions detected!");
		return;
	}

	for (i = 0; i < NUM_FIRE_MODES; i++)
	{
		if (InstantFire(FireMode[i]) != None && InstantFire(FireMode[i]).DamageType == DamageType)
		{
			//HACK - compensate for shock rifle not firing on crosshair
			if(ShockBeamFire(FireMode[i]) != None && PlayerController(Instigator.Controller) != None)
			{
				StartTrace = Instigator.Location + Instigator.EyePosition();
				GetViewAxes(X,Y,Z);
				StartTrace = StartTrace + X*class'ShockProjFire'.Default.ProjSpawnOffset.X;
				if (!WeaponCentered())
					StartTrace = StartTrace + Hand * Y*class'ShockProjFire'.Default.ProjSpawnOffset.Y + Z*class'ShockProjFire'.Default.ProjSpawnOffset.Z;
				
				Recursions++;
				InstantFire(FireMode[i]).DoTrace(HitLocation + Normal(HitLocation - StartTrace) * Victim.CollisionRadius * 2, rotator(HitLocation - StartTrace));
				Recursions--;
			}
			else
			{
				Recursions++;
				InstantFire(FireMode[i]).DoTrace(HitLocation + Normal(HitLocation - (Instigator.Location + Instigator.EyePosition())) * Victim.CollisionRadius * 2, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				Recursions--;
			}
			return;
		}
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= PenetratingText;
	return text;
}

defaultproperties
{
	DamageBonus=0.050000
	MinModifier=-2
	MaxModifier=4
	bCanHaveZeroModifier=True
	PatternPos="Penetrating $W"
	PatternNeg="Penetrating $W"
	PenetratingText="fires through enemies"
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.PlayerTrans'
}
