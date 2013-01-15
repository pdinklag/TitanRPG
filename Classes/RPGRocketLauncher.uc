class RPGRocketLauncher extends RocketLauncher
	HideDropDown
	CacheExempt;

var class<RocketProj> RocketClass;
var class<SeekingRocketProj> SeekingRocketClass;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local RocketProj Rocket;
    local SeekingRocketProj SeekingRocket;
	local bot B;

    bBreakLock = true;

	// decide if bot should be locked on
	B = Bot(Instigator.Controller);
	if ( (B != None) && (B.Skill > 2 + 5 * FRand()) && (FRand() < 0.6) && (B.Target != None)
		&& (B.Target == B.Enemy) && (VSize(B.Enemy.Location - B.Pawn.Location) > 2000 + 2000 * FRand())
		&& (Level.TimeSeconds - B.LastSeenTime < 0.4) && (Level.TimeSeconds - B.AcquireTime > 1.5) )
	{
		bLockedOn = true;
		SeekTarget = B.Enemy;
	}

    if (bLockedOn && SeekTarget != None)
    {
		SeekingRocket = Spawn(SeekingRocketClass,,, Start, Dir);
		
        SeekingRocket.Seeking = SeekTarget;
        if ( B != None )
        {
			bLockedOn = false;
			SeekTarget = None;
		}
        return SeekingRocket;
    }
    else
    {
		Rocket = Spawn(RocketClass,,, Start, Dir);
        return Rocket;
    }
}

defaultproperties
{
	RocketClass=class'RPGRocketProj';
	SeekingRocketClass=class'RPGSeekingRocketProj';
    
    FireModeClass(0)=class'RocketFire'
    FireModeClass(1)=class'RPGRocketMultiFire';

	PickupClass=class'RPGRocketLauncherPickup'
}
