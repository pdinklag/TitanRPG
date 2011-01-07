//Drone rewrite
class Drone extends Actor
	config(TitanRPG);

//Server
var Pawn PawnOwner;

//Simulated
var float OrbitMaxDist;

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

var float BackInOrbitDistance;

var config float OrbitDist, OrbitHeight;
var config float Speed;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientSync;

	reliable if(Role == ROLE_Authority && bNetDirty)
		PawnLocation, PawnRotation, Team,
		OrbitDist, OrbitHeight,
		Speed;
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
	
	OrbitMaxDist = 1.33f * VSize(OrbitDist * vect(1, 0, 0) + OrbitHeight * vect(0, 0, 1));

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
	SetRotation(rotator(Dir)); //TODO: unless there is a firing target
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
		SetLocation(ServerLocation);
		GotoState(ServerState);
	}
}

simulated function vector Flatten(vector v)
{
	v.Z = 0;
	return v;
}

//Orbit around the player
state Orbiting
{
	simulated function BeginState()
	{
		Log(Self @ "Orbiting");
	
		if(Role == ROLE_Authority)
			Sync();
	}
	
	simulated event Tick(float dt)
	{
		local float Dist;
		local vector X, Y, Z;
	
		Global.Tick(dt);
		
		Dist = VSize(Location - PawnLocation);
		if(VSize(Location - PawnLocation) <= OrbitMaxDist)
		{
			GetAxes(rotator(Flatten(PawnLocation - Location)), X, Y, Z);
			
			if(Dist < OrbitDist)
				Y -= X;
			else
				Y += X;
			
			//Y.Z = (PawnLocation.Z + OrbitHeight) - Location.Z;
			
			SetDirection(Y);
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
		Log(Self @ "Following");
	
		if(Role == ROLE_Authority)
			Sync();
	}

	//find tangent point on the circle PawnLocation/OrbitDist
	simulated function vector CalculateMoveTarget()
	{
		local vector X, Y, Z;
		
		GetAxes(rotator(Flatten(PawnLocation - Location)), X, Y, Z);
		return PawnLocation + OrbitDist * Y + OrbitHeight * vect(0, 0, 1);
	}

	simulated event Tick(float dt)
	{
		Global.Tick(dt);

		if(VSize(Location - PawnLocation) > OrbitMaxDist)
			SetDirection(CalculateMoveTarget() - Location);
		else if(Role == ROLE_Authority)
			GotoState('Orbiting');
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
	OrbitDist=128.0f;
	OrbitHeight=32.0f;

	Speed=200.0f //movement speed
	
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
