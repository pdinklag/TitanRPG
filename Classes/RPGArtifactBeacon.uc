class RPGArtifactBeacon extends Projectile;

var bool bLanded;
var ArtifactBase_Beacon Artifact;

var int WallHits;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	Velocity = vector(Rotation) * Speed;
}

simulated event Landed(vector HitNormal)
{
    HitWall(HitNormal, None);
}

simulated event HitWall( vector HitNormal, actor Wall )
{
	if(Wall.bWorldGeometry && HitNormal.Z >= 0.8) //landed on floor (no or only gentle slope)
	{
		if(Level.NetMode != NM_DedicatedServer)
			PlaySound(ImpactSound, SLOT_Misc);
		
		bBounce = false;
		SetPhysics(PHYS_None);

		if(Role == ROLE_Authority)
		{
			bLanded = true;
			
			Artifact.BeaconLanded(Self);
			Destroy();
		}
	}
	else
	{
		Velocity = 0.3 * ((Velocity dot HitNormal) * HitNormal * (-2.0) + Velocity);
		Speed = VSize(Velocity);
		
		if(Role == ROLE_Authority)
		{
			WallHits++;
			if(WallHits > 10) //most likely stuck
				Destroy();
		}
	}
}

simulated event Destroyed()
{
	if(Role == ROLE_Authority && !bLanded)
		Artifact.BeaconDestroyed(Self);
	
	Super.Destroyed();
}

defaultproperties
{
    Speed=1200
    MaxSpeed=2000
    Damage=0
    DamageRadius=100
    MomentumTransfer=50000
	ImpactSound=Sound'WeaponSounds.P1GrenFloor1'
    Physics=PHYS_Falling
    DrawType=DT_StaticMesh

    AmbientGlow=64
    bUnlit=true
    bBounce=true
    bNetTemporary=false
    bUpdateSimulatedPosition=true
	NetUpdateFrequency=8
    AmbientSound=Sound'WeaponSounds.Redeemer_Flight'

    CollisionRadius=10.000000
	CollisionHeight=10.00000
	PrePivot=(X=0.0,Y=0.0,Z=25.0)
    SoundRadius=7
    SoundVolume=250
    SoundPitch=128
	bOnlyDirtyReplication=true
	bOwnerNoSee=true
	
	bProjTarget=false
}
