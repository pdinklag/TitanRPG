class WeaponModifier_Force extends RPGWeaponModifier;

const FORCE_RADIUS = 32768;

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

function RPGTick(float dt) {
    local Projectile Proj;
    local float Multiplier;

    Super.RPGTick(dt);

    Multiplier = 1.0f + BonusPerLevel * float(Modifier);

    foreach Instigator.CollidingActors(class'Projectile', Proj, FORCE_RADIUS) {
        if(Proj.Tag == 'Force' || Proj.Tag == 'Matrix') {
            continue;
        }

        if(Proj.Instigator != Instigator) {
            continue;
        }

        Identify();

        Proj.Tag = 'Force';
        class'Util'.static.ModifyProjectileSpeed(Proj, Multiplier, 'Force');
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
    bCanHaveZeroModifier=False
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.PlayerTransRed'
	PatternPos="$W of Force"
	PatternNeg="$W of Slow Motion"
	//AI
	AIRatingBonus=0.000000
}
