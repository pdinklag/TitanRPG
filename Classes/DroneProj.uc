class DroneProj extends Projectile;

var Emitter projEffect;
var byte Team;

replication
{
	reliable if(Role==ROLE_Authority && bNetInitial)
		Team;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if(Role == ROLE_Authority)
	{
		if(Pawn(Owner) != None)
			Team = Pawn(Owner).GetTeamNum();
	}
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	Velocity = Speed * vector(Rotation);
	Acceleration = Velocity;
	if(Level.NetMode != NM_DedicatedServer)
	{
		if(Team == 0)
			projEffect = Spawn(class'DroneProjEffectRed', Self,, Location, Rotation);
		else if(Team == 1)
			projEffect = Spawn(class'DroneProjEffectBlue', Self,, Location, Rotation);
		else if(Team == 2) //OLTeamGames
			projEffect = Spawn(class'DroneProjEffectGreen', Self,, Location, Rotation);
		else
			projEffect = Spawn(class'DroneProjEffect', Self,, Location, Rotation);
		
		
		if(projEffect != None)
			projEffect.SetBase(self);
	}
	
}

simulated event Destroyed()
{
	if(projEffect != None)
		projEffect.Destroy();
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	if ( !Other.IsA('Projectile') || Other.bProjTarget )
	{
		if ( Role == ROLE_Authority )
		{
			Other.TakeDamage(Damage,Instigator,HitLocation,MomentumTransfer * Normal(Velocity),MyDamageType);
		}
		Explode(HitLocation, vect(0,0,1));
	}
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    PlaySound(Sound'WeaponSounds.BioRifle.BioRifleGoo2');
	Destroy();
}

defaultproperties
{
	Team=255
	Speed=1200.000000
	MaxSpeed=2400.000000
	Damage=9.000000
	MomentumTransfer=1600.000000
	MyDamageType=Class'DamTypeDronePlasma'
	DrawType=DT_None
	bNetTemporary=False
	AmbientSound=Sound'WeaponSounds.LinkGun.LinkGunProjectile'
	LifeSpan=3.000000
	SoundVolume=255
	SoundRadius=50.000000
	ForceType=FT_Constant
	ForceRadius=30.000000
	ForceScale=5.000000
}
