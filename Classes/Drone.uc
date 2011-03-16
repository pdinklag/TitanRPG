//Drone rewrite
class Drone extends Actor
	config(TitanRPG);

//Server
var Pawn PawnOwner;

//Simulated
var float AngularSpeed, OrbitYaw, OrbitWobble;

//Replication
var PlayerReplicationInfo OwnerPRI;
var byte Team;
var vector PawnLocation;
var rotator PawnRotation;

//Client
var byte CurrentTeam;
var ColoredTrail Trail;

//Settings
var Material TeamSkin[4];
var Color TeamTrailColor[4], DefaultTrailColor;

var float OrbitOuterTreshold, OrbitInnerTreshold;
var float SyncInterval, SyncTreshold;

var float OrbitHeight;

var config float OrbitRadius, OrbitHeightMin, OrbitHeightMax, OrbitWobbleZ, OrbitWobbleSpeed;
var config float Speed;

const RAD_TO_ROT = 10430.378350f; //32768 / Pi

replication
{
	reliable if(Role == ROLE_Authority)
		ClientSync;
	
	reliable if(Role == ROLE_Authority && bNetInitial)
		Speed,
		OrbitRadius, OrbitHeight, OrbitWobbleZ, OrbitWobbleSpeed, OrbitInnerTreshold, OrbitOuterTreshold;

	unreliable if(Role == ROLE_Authority && bNetDirty)
		PawnLocation, PawnRotation, Team;
	
	unreliable if(Role == ROLE_Authority && IsInState('Orbiting'))
		OrbitYaw, OrbitWobble;
}

static function Drone SpawnFor(Pawn Other)
{
	local Drone Drone;
	local RPGPlayerReplicationInfo RPRI;
	
	//check if max drones was reached
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Other.Controller);
	
	if(RPRI != None && RPRI.Drones.Length >= RPRI.MaxDrones)
		return None;
	
	Drone = Other.Spawn(
		class'Drone',
		Other,,
		Other.Location + (Other.CollisionHeight + default.CollisionHeight) * vect(0, 0, 1),
		Other.Rotation);

	if(RPRI != None)
		RPRI.AddDrone(Drone);
	
	return Drone;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if(Role == ROLE_Authority)
	{
		PawnOwner = Pawn(Owner);
		
		if(PawnOwner == None)
			Destroy();
		
		OwnerPRI = PawnOwner.PlayerReplicationInfo;
		
		if(OwnerPRI != None && OwnerPRI.Team != None)
			Team = OwnerPRI.Team.TeamIndex;
		else
			Team = 255;
		
		OrbitHeight = OrbitHeightMin + FRand() * (OrbitHeightMax - OrbitHeightMin);
		OrbitWobble = FRand() * Pi;
		
		SetTimer(SyncInterval, true);
	}
	
	if(Level.NetMode != NM_DedicatedServer)
	{
		Trail = Spawn(class'ColoredTrail', Self,, Location, Rotation);
		Trail.SetBase(Self);
		Trail.LifeSpan = 99999;
	}
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if(Level.NetMode != NM_DedicatedServer)
		ChangedTeam();
	
	AngularSpeed = (Speed / OrbitRadius) * RAD_TO_ROT;

	GotoState('Orbiting');
}

simulated function ChangedTeam()
{
	CurrentTeam = Team;
	
	if(Team >= 0 && Team < 4)
	{
		Skins[0] = TeamSkin[Team];
		Trail.Color = TeamTrailColor[Team];
	}
	else
	{
		Skins[0] = None;
		Trail.Color = DefaultTrailColor;
	}
}

simulated event Tick(float dt)
{
	if(Role == ROLE_Authority)
	{
		if(PawnOwner == None || PawnOwner.Health <= 0)
		{
			Destroy();
			return;
		}
		else
		{
			PawnLocation = PawnOwner.Location;
			PawnRotation = PawnOwner.Rotation;
		}
		
		if(OwnerPRI != None && OwnerPRI.Team != None)
			Team = OwnerPRI.Team.TeamIndex;
		else
			Team = 255;
	}

	if(Level.NetMode != NM_DedicatedServer && Team != CurrentTeam)
		ChangedTeam();
}

simulated function SetDirection(vector Dir)
{
	Velocity = Speed * Normal(Dir);
	SetRotation(rotator(Flatten(Dir))); //TODO: unless there is a firing target
}

function Timer()
{
	Sync();
}

function Sync()
{
	if(Level.NetMode != NM_Standalone)
		ClientSync(Location, GetStateName());
}

simulated function ClientSync(vector ServerLocation, name ServerState)
{
	if(Role < ROLE_Authority)
	{
		if(!IsInState(ServerState))
			GotoState(ServerState);

		if(Abs(VSize(Location - PawnLocation) / VSize(ServerLocation - PawnLocation)) >= SyncTreshold)
		{
			SetLocation(ServerLocation);
			StateUpdateLocation();
		}
	}
}

simulated function StateUpdateLocation();

simulated function vector Flatten(vector v)
{
	v.Z = 0;
	return v;
}

//Orbit around the player
state Orbiting
{
	simulated function StateUpdateLocation()
	{
		local rotator r;
	
		r = rotator(Flatten(Location - PawnLocation));
		OrbitYaw = r.Yaw;
	}

	simulated function BeginState()
	{
		StateUpdateLocation();
	
		if(Role == ROLE_Authority)
			Sync();
	}
	
	simulated event Tick(float dt)
	{
		local float Dist, OutOfOrbit, Z;
		local vector MoveTarget;
		
		Global.Tick(dt);
		
		Dist = VSize(Flatten(Location - PawnLocation));
		OutOfOrbit = Dist / OrbitRadius;
		
		if(OutOfOrbit < OrbitOuterTreshold)
		{
			OrbitYaw += AngularSpeed * dt;
			OrbitWobble += OrbitWobbleSpeed * dt;
			
			MoveTarget =
				PawnLocation + OrbitRadius * vector(OrbitYaw * rot(0, 1, 0)) +
				(OrbitHeight + OrbitWobbleZ * Sin(OrbitWobble)) * vect(0, 0, 1);

			SetDirection(MoveTarget - Location);
		}
		else if(Role == ROLE_Authority)
		{
			GotoState('Following');
		}
	}
}

//Follow the player
state Following
{
	simulated function BeginState()
	{
		if(Role == ROLE_Authority)
			Sync();
	}

	//find tangent
	simulated function vector CalculateMoveDir()
	{
		local vector d;
	
		d = Flatten(PawnLocation - Location);
		return 
			(d >> (rot(0, -1, 0) * RAD_TO_ROT * ASin(OrbitRadius / VSize(d)))) +
			(PawnLocation.Z + OrbitHeight - Location.Z) * vect(0, 0, 1);
	}

	simulated event Tick(float dt)
	{
		Global.Tick(dt);
		
		if(VSize(Flatten(PawnLocation - Location)) > OrbitRadius * OrbitOuterTreshold)
		{
			SetDirection(CalculateMoveDir());
		}
		else if(Role == ROLE_Authority)
		{
			OrbitWobble = 0.0f;
			GotoState('Orbiting');
		}
	}

	simulated function EndState()
	{
	}
}

simulated event Destroyed()
{
	Super.Destroyed();
	
	if(Trail != None)
		Trail.Destroy();
}

defaultproperties
{
	OrbitWobbleZ=16.00
	OrbitWobbleSpeed=3.141593 // Pi

	OrbitOuterTreshold=1.025
	OrbitInnerTreshold=0.95
	
	SyncInterval=2.0
	SyncTreshold=0.05

	OrbitRadius=96.00
	OrbitHeightMin=0.00
	OrbitHeightMax=40.00

	Speed=300.00 //movement speed
	
	Team=255

	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'<? echo($packageName); ?>.Drones.DroneMesh'
	DrawScale=2.500000
	bUnlit=True
	
	DefaultTrailColor=(R=255,G=255,B=0,A=255)	
	TeamTrailColor(0)=(R=255,G=0,B=0,A=255)
	TeamTrailColor(1)=(R=0,G=0,B=255,A=255)
	TeamTrailColor(2)=(R=0,G=255,B=0,A=255)
	TeamTrailColor(3)=(R=255,G=224,B=0,A=255)
	
	TeamSkin(0)=Texture'<? echo($packageName); ?>.Drones.DroneTexRed'
	TeamSkin(1)=Texture'<? echo($packageName); ?>.Drones.DroneTexBlue'
	TeamSkin(2)=Texture'<? echo($packageName); ?>.Drones.DroneTexGreen'
	TeamSkin(3)=Texture'<? echo($packageName); ?>.Drones.DroneTex'
	
	//RotationRate=(Yaw=24000)
	//DesiredRotation=(Yaw=30000)	
	//bFixedRotationDir=True
	
	bBounce=True
	
	Physics=PHYS_Projectile
	
	bUseCylinderCollision=True
	CollisionRadius=20.000000
	CollisionHeight=20.000000
	bCollideActors=True
	bCollideWorld=True
	bDisturbFluidSurface=True
	
	AmbientSound=Sound'WeaponSounds.LinkGun.LinkGunProjectile'
	SoundVolume=255
	SoundRadius=50

	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
