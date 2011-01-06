//Drone rewrite
class Drone extends Actor
	config(TitanRPG);

//Server
var Pawn PawnOwner;

//Simulated
var float OrbitAngle, AngularSpeed, OrbitMaxDist;

//Replication
var PlayerReplicationInfo OwnerPRI;
var byte Team;
var vector PawnLocation;

//Client
var byte CurrentTeam;
var ColoredTrail Trail;

//Settings
var Material TeamSkin[4];
var Color TeamTrailColor[4], DefaultTrailColor;

var config float OrbitDist, OrbitHeight;
var config float Speed, OrbitTime;

replication
{
	reliable if(Role == ROLE_Authority && bNetDirty)
		PawnLocation, Team,
		OrbitDist, OrbitHeight,
		Speed, OrbitTime;
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
		Other.Location + default.OrbitDist * vect(1, 0, 0) + default.OrbitHeight * vect(0, 0, 1),
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
	
	OrbitMaxDist = 1.25f * VSize(OrbitDist * vect(1, 0, 0) + OrbitHeight * vect(0, 0, 1));
	AngularSpeed = -2.0f * Pi / OrbitTime;
	
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
		}
		
		if(OwnerPRI != None && OwnerPRI.Team != None)
			Team = OwnerPRI.Team.TeamIndex;
		else
			Team = 255;
	}

	if(Level.NetMode != NM_DedicatedServer && Team != CurrentTeam)
		ChangedTeam();
}

simulated function SetMoveTarget(vector MoveTarget)
{
	local vector MoveDelta;

	MoveDelta = MoveTarget - Location;
	
	Velocity = Speed * Normal(MoveDelta);
	SetRotation(rotator(MoveDelta)); //TODO: unless there is a firing target
}

//Orbit around the player
state Orbiting
{
	simulated function BeginState()
	{
		OrbitAngle = ACos(Normal(Location - PawnLocation) dot vect(1, 0, 0));
		Log(Self @ "begin orbiting, OrbitAngle =" @ OrbitAngle);
	}

	simulated event Tick(float dt)
	{
		Global.Tick(dt);
		
		if(VSize(Location - PawnLocation) <= OrbitMaxDist)
		{
			SetMoveTarget(
				PawnLocation +
				Cos(OrbitAngle) * OrbitDist * vect(1, 0, 0) +
				Sin(OrbitAngle) * OrbitDist * vect(0, 1, 0) +
				OrbitHeight * vect(0, 0, 1));
			
			OrbitAngle += AngularSpeed;
		}
		else
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
		Log(Self @ "begin following");
	}

	simulated event Tick(float dt)
	{
		local vector FlatDir;
	
		Global.Tick(dt);
		
		FlatDir = Normal(Location - PawnLocation);
		FlatDir.Z = 0;
		
		if(VSize(Location - PawnLocation) > OrbitMaxDist)
		{	
			SetMoveTarget(
				PawnLocation +
				OrbitDist * FlatDir +
				OrbitHeight * vect(0, 0, 1));
		}
		else
		{
			GotoState('Orbiting');
		}
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
	OrbitDist=200.0f;
	OrbitHeight=32.0f;

	Speed=200.0f //movement speed
	OrbitTime=2.0f //2 seconds for one orbit

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
