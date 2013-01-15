class RPGRocketMultiFire extends RocketMultiFire;

/**
    Basically unmodified from RocketMultiFire, but increased size of FiredRockets array.
*/
function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;
    local Vector HitLocation, HitNormal,FireLocation;
    local Actor Other;
    local int p,q, SpawnCount, i;
	local RocketProj FiredRockets[16];
	local bool bCurl;
	
	if ( (SpreadStyle == SS_Line) || (Load < 2) )
	{
		Super(ProjectileFire).DoFireEffect();
		return;
	}
	
    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();
    StartProj = StartTrace + X*ProjSpawnOffset.X + Z*ProjSpawnOffset.Z;
    if ( !Weapon.WeaponCentered() )
	    StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != None)
    {
        StartProj = HitLocation;
    }
    
    Aim = AdjustAim(StartProj, AimError);

    SpawnCount = Max(1, int(Load));

    for ( p=0; p<SpawnCount; p++ )
    {
 		Firelocation = StartProj - 2*((Sin(p*2*PI/MaxLoad)*8 - 7)*Y - (Cos(p*2*PI/MaxLoad)*8 - 7)*Z) - X * 8 * FRand();
        FiredRockets[p] = RocketProj(SpawnProjectile(FireLocation, Aim));
    }
    
    if ( SpawnCount < 2 )
		return;
	
	FlockIndex++;
	if ( FlockIndex == 0 )
		FlockIndex = 1;
		
    // To get crazy flying, we tell each projectile in the flock about the others.
    for ( p = 0; p < SpawnCount; p++ )
    {
		if ( FiredRockets[p] != None )
		{
			FiredRockets[p].bCurl = bCurl;
			FiredRockets[p].FlockIndex = FlockIndex;
			i = 0;
			for ( q=0; q<SpawnCount; q++ )
				if ( (p != q) && (FiredRockets[q] != None) )
				{
                    FiredRockets[p].Flock[i % 2] = FiredRockets[q];
					i++;
				}	
			bCurl = !bCurl;
			if ( Level.NetMode != NM_DedicatedServer )
				FiredRockets[p].SetTimer(0.1, true);
		}
	}
}

/**
    Override to remove limit of 3 rockets.
*/
function ModeTick(float dt)
{
    local int i;

    // auto fire if loaded last rocket
    if (HoldTime > 0.0 && Load >= Weapon.AmmoAmount(ThisModeNum) && !bNowWaiting)
    {
        bIsFiring = false;
    }

    Super(ProjectileFire).ModeTick(dt);
    
    if(Load == MaxLoad - 1 && HoldTime >= FireRate * (MaxLoad - 1)) {
        //final rocket
        Load += 1;
    } else {
        for(i = 1; i < MaxLoad - 1; i++) {
            if(Load == i && HoldTime >= FireRate * i) {
                //animate
                if (Instigator.IsLocallyControlled()) {
                    RocketLauncher(Weapon).PlayLoad(false);
                } else {
                    ServerPlayLoading();
                }
                    
                Load += 1;
                break;
            }
        }
    }
}

defaultproperties {
}
