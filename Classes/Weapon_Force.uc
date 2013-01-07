class Weapon_Force extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string ProjSpeedText;

var int LastFlashCount;

function SetModifiedWeapon(Weapon w, bool bIdentify)
{
	Super.SetModifiedWeapon(w, bIdentify);

	if (ProjectileFire(FireMode[0]) != None && ProjectileFire(FireMode[1]) != None)
		AIRatingBonus *= 1.5;
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	
	if(!Super.AllowedFor(Weapon, Other))
		return false;

	for (x = 0; x < NUM_FIRE_MODES; x++)
	{
		if (class<ProjectileFire>(Weapon.default.FireModeClass[x]) != None)
			return true;
	}

	return false;
}

function ModifyProjectile(Projectile P)
{
	local Sync_ProjectileSpeed Sync;
	local float Multiplier;

	Identify();

	Multiplier = 1.0 + BonusPerLevel * Modifier;
	if(Multiplier != 0.0)
	{
		P.Tag = 'Force';
		P.Speed *= Multiplier;
		P.MaxSpeed *= Multiplier;
		P.Velocity *= Multiplier;
		
		//Tell clients
		if(Level.NetMode == NM_DedicatedServer)
		{
			Sync = Instigator.Spawn(class'Sync_ProjectileSpeed');
			Sync.Proj = P;
			Sync.ProjClass = P.class;
			Sync.ProcessedTag = 'Force';
			Sync.SpeedMultiplier = Multiplier;
		}
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(ProjSpeedText, "$1", GetBonusPercentageString(BonusPerLevel));
	return text;
}

defaultproperties
{
	DamageBonus=0.040000
	BonusPerLevel=0.200000
	ProjSpeedText="$1 projectile speed"
	MinModifier=-4
	MaxModifier=10
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.PlayerTransRed'
	PatternPos="$W of Force"
	PatternNeg="$W of Slow Motion"
	//AI
	AIRatingBonus=0.000000
}
