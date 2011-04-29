class WeaponModifier_Force extends RPGWeaponModifier;

var localized string ProjSpeedText;

static function bool AllowedFor(class<Weapon> WeaponType, Pawn Other)
{
	local int x;
	
	if(!Super.AllowedFor(WeaponType, Other))
		return false;

	for(x = 0; x < ArrayCount(WeaponType.default.FireModeClass); x++)
	{
		if (class<ProjectileFire>(WeaponType.default.FireModeClass[x]) != None)
			return true;
	}

	return false;
}

function RPGTick(float dt)
{
	local float Multiplier;
	local Projectile Proj;
	local Sync_ProjectileSpeed Sync;

	//Projectiles
	foreach Instigator.VisibleCollidingActors(class'Projectile', Proj, 256)
	{
		if(Proj.Instigator == Instigator && Proj.Tag == Proj.class.Name)
		{
			Identify();
			
			Proj.Tag = default.class.Name; //process only once

			Multiplier = 1.0f + BonusPerLevel * float(Modifier);
			if(Multiplier != 0)
			{
				Proj.Speed *= Multiplier;
				Proj.MaxSpeed *= Multiplier;
				Proj.Velocity *= Multiplier;
				
				//Tell clients
				if(Level.NetMode == NM_DedicatedServer)
				{
					Sync = Instigator.Spawn(class'Sync_ProjectileSpeed');
					Sync.Proj = Proj;
					Sync.ProjClass = Proj.class;
					Sync.ProcessedTag = default.class.Name;
					Sync.SpeedMultiplier = Multiplier;
				}
			}
		}
	}
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(ProjSpeedText, BonusPerLevel);
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
