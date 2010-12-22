class Drone extends Actor
	config(TitanRPG);

var config int HealPerSec; //health given per second
var config int HealDist; //maximum distance at which owner can be healed

var config int ProjDamage; //damage done by projectiles

var int ShotDelay; //delay between shots
var int TargetDelay; //delay between retargets

var float Speed;
var int CircleSpeed; //orbital speed
var int OscHeight; //several times the actual weave height
var float OscInc; //increment of oscillation - rate of weaving

var int orbitHeight; //vertical offset from player's center - randomized when player has more than one

var Pawn protPawn; //owner pawn
var byte TeamNum;
var int OrbitDist; //distance at which drone orbits when pawn's not moving

var ColoredTrail Trail;
var DroneHealBeam healBeam;

var int healCounter; //counter to keep track of healing

var float CountUp;

var float curOsc; //oscillation counter
var int shootCounter; //counter to keep track of shots

var int targetCounter; //counter to keep track of targeting
var Pawn targetPawn; //target.. um.. pawn?
var int TargetRadius; //radius in which drone will look for targets

var Material RedSkin, BlueSkin, GreenSkin, GoldSkin;
var Color RedTrail, BlueTrail, GreenTrail, GoldTrail, DefaultTrail;

/*
	If the drone's distance from the Pawn is greater than [ResetPawnDistance] for
	over [ResetTime] seconds, it is considered stuck and gets Reset. ~pd
*/
var float ResetPawnDistance, ResetTime, LastResetCheckTime, LostTime;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		protPawn, HealPerSec, ShotDelay, TargetDelay, ProjDamage, curOsc, shootCounter, targetCounter, orbitHeight;
		
	reliable if(Role == ROLE_Authority)
		ClientReset;
}

static function Drone SpawnFor(Pawn Other)
{
	local int Num;
	local Drone D;
	local RPGPlayerReplicationInfo RPRI;
	
	if(Other != None && Other.Health > 0)
	{
		//check if max drones was reached
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Other.Controller);
		if(RPRI != None && RPRI.Drones.Length >= RPRI.MaxDrones)
		{
			return None;
		}
		else
		{
			foreach Other.AllActors(class'Drone', D)
			{
				if(D.protPawn == Other)
					Num++;
			}
			
			if(Num >= class'MutTitanRPG'.static.Instance(Other.Level).MaxDrones)
				return None;
		}
		D = Other.Spawn(class'Drone', Other,, Other.Location + vect(0, -32, 64), Other.Rotation);
		D.protPawn = Other;
		D.ProjDamage = default.ProjDamage;
		D.HealPerSec = default.HealPerSec;
		D.ShotDelay = default.ShotDelay;
		D.TargetDelay = default.TargetDelay;
		
		if(RPRI != None)
			RPRI.AddDrone(D);
	}
	
	return D;
}

//called every once in a while to check whether this Drone is stuck and should be reset ~pd
function bool CheckReset()
{
	local float PawnDistance, dt;

	dt = Level.TimeSeconds - LastResetCheckTime;
	LastResetCheckTime = Level.TimeSeconds;

	if(protPawn != None)
	{
		PawnDistance = VSize(Location - protPawn.Location);
		if(PawnDistance > ResetPawnDistance)
		{
			LostTime += dt;
			
			if(LostTime > ResetTime)
			{
				//stuck, reset
				SetLocation(protPawn.Location + vect(0, -32, 64));
				SetRotation(protPawn.Rotation);
				Velocity = vector(Rotation) * Speed;
				LostTime = 0.f;
				
				ClientReset(Location, Rotation);
				
				return true;
			}
		}
		else
		{
			LostTime = 0.f;
		}
	}
	
	return false;
}

simulated function ClientReset(vector NewLocation, rotator NewRotation)
{
	if(Role < ROLE_Authority)
	{
		SetLocation(NewLocation);
		SetRotation(NewRotation);
		Velocity = vector(Rotation) * Speed;
	}
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	//randomize everything so drones behave a little bit differently
	if(Role == ROLE_Authority)
	{
		curOsc = FRand() * 3.14159;
		shootCounter = FRand() * ShotDelay;
		targetCounter = FRand() * TargetDelay;
		orbitHeight = FRand() * 95 - 40;
		
		LastResetCheckTime = Level.TimeSeconds;
	}
	
	if(Level.NetMode != NM_DedicatedServer)
	{
		Trail = Spawn(class'ColoredTrail', Self,, Location, Rotation);
		Trail.SetBase(Self);
		Trail.LifeSpan = 99999;
	}
	
	SetTeamNum(255);
	
	Velocity = vector(Rotation) * Speed;
	SetTimer(0.1, true);
}

simulated function SetTeamNum(byte x)
{
	TeamNum = x;

	if(TeamNum == 0)
	{
		Skins[0] = RedSkin;
		
		if(Trail != None)
			Trail.Color = RedTrail;
	}
	else if(TeamNum == 1)
	{
		Skins[0] = BlueSkin;
		
		if(Trail != None)
			Trail.Color = BlueTrail;
	}
	//OLTeamGames
	else if(TeamNum == 2)
	{
		Skins[0] = GreenSkin;
		
		if(Trail != None)
			Trail.Color = GreenTrail;
	}
	else if(TeamNum == 3)
	{
		Skins[0] = GoldSkin;
		
		if(Trail != None)
			Trail.Color = GoldTrail;
	}
	else
	{
		Skins[0] = None;
		
		if(Trail != None)
			Trail.Color = DefaultTrail;
	}
}

simulated event Tick(float dt)
{
	local byte Team;

	Super.Tick(dt);

	//if there's a healing beam, update it every tick (timer would have noticeable lag)
	if(healBeam != None && protPawn != None)
	{
		healBeam.mSpawnVecA = protPawn.Location;
		healBeam.SetRotation(rotator(protPawn.Location + vect(0, 0, 48) - Location));
	}
	
	if(protPawn != None && protPawn.PlayerReplicationInfo != None && protPawn.PlayerReplicationInfo.Team != None)
	{
		Team = protPawn.PlayerReplicationInfo.Team.TeamIndex;
		if(Team != TeamNum)
			SetTeamNum(Team);
	}

    if(Role == ROLE_Authority)
	{
		if(protPawn == None || protPawn.Health <= 0)
		{
			Destroy();
			return;
		}
    }
}

simulated function Timer()
{
	local Pawn cTarget;
	local vector toProt;
	local int protTeam;
	local float dist;
	local DroneProj dp;

	if(protPawn == None || protPawn.Health <= 0)
	{
		Destroy();
	}
	else
	{
		//Movement
		CheckReset(); //~pd
		
		curOsc += OscInc;
		toProt = (protPawn.Location + vect(0, 0, 1) * orbitHeight) - Location;
		dist = VSize(toProt);
		Velocity = 0.1 * Velocity + 0.3 * ((Normal(toProt) cross vect(0,0,1)) * CircleSpeed) + 0.2 * cos(curOsc) * vect(0,0,1) * OscHeight + 0.4 * Normal(toProt) * Speed * (dist - OrbitDist)/OrbitDist;
		SetRotation(rotator(Velocity) + rotator(vect(1,0,0)) + rotator(vect(0,1,0)));
			
		//Healing
		healCounter++;
		if(dist < HealDist)
		{
			if(healBeam == None && protPawn.Health < protPawn.HealthMax && protPawn.Health>0 && targetPawn == None && Level.NetMode != NM_DedicatedServer)
			{
				healBeam = Spawn(class'DroneHealBeam', self, , Location, rotator(protPawn.Location - Location));
				healBeam.SetBase(self);
				healBeam.SetTeamNum(TeamNum);
			}
		}
		
		if((dist > HealDist + 16 || protPawn.Health >= protPawn.HealthMax) && healBeam != None)
			healBeam.Destroy();
		
		if(healCounter == 2)
		{
			if(dist < HealDist && protPawn.Health>0 && targetPawn == None && Role == ROLE_Authority)
				protPawn.GiveHealth(HealPerSec / 5, protPawn.HealthMax);
			
			healCounter = 0;
		}
		
		//Server-side stuff
		if(Role == ROLE_Authority)
		{
			//Targeting
			if(targetCounter >= TargetDelay && protPawn.Health > 0)
			{
				protTeam = protPawn.GetTeamNum();
				targetPawn = None;
				foreach VisibleCollidingActors(class'Pawn',cTarget,TargetRadius)
				{
					if(cTarget.IsA('Vehicle') && Vehicle(cTarget).IsVehicleEmpty())
						continue; //don't fire at empty vehicles
				
					if(cTarget != protPawn && (!Level.Game.bTeamGame || cTarget.GetTeamNum() != protTeam) && cTarget.Health>0)
					{
						if(targetPawn==None)
							targetPawn=cTarget;
						else if(VSize(targetPawn.Location-protPawn.Location)>VSize(cTarget.Location-protPawn.Location))
							targetPawn=cTarget;
					}
				}
				
				targetCounter=0;
			}
			targetCounter++;
			
			//Shooting
			if(shootCounter>=ShotDelay)
			{
				if(targetPawn!=None)
				{
					// omg shoot at it
					dp = Spawn(class'DroneProj',protPawn,,Location + Normal(targetPawn.Location-Location)*32,rotator(targetPawn.Location-Location));
					if(dp != None)
					{
						// set projectile instigator so owner gets kill credit
						dp.Instigator = protPawn;
						dp.Damage = ProjDamage;
						PlaySound(Sound'WeaponSounds.LinkGun.BLinkedFire', SLOT_None, 100.0);
						
						// we don't heal while we're shooting
						if(healBeam!=None)
							healBeam.Destroy();
					}
				}
				shootCounter=0;
			}
			shootCounter++;
		}
	}
}

simulated event HitWall(vector HitNormal, actor Wall)
{
	//bounce off. this makes for some weirdness with the homing but it's not too bad
	Velocity = -(Velocity dot HitNormal) * HitNormal;
	SetRotation(rotator(Velocity));
}

simulated event Destroyed()
{
	if(Trail != None)
		Trail.Destroy();

	if(healBeam != None)
		healBeam.Destroy();
}

defaultproperties
{
	ResetPawnDistance=1000.000000
	ResetTime=3.000000
	Speed=800.000000
	OrbitDist=64
	HealDist=400
	CircleSpeed=800
	OscHeight=240
	OscInc=0.500000
	TargetRadius=2000
	HealPerSec=10
	ShotDelay=6
	TargetDelay=15
	ProjDamage=9
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'<? echo($packageName); ?>.Drones.DroneMesh'
	DefaultTrail=(R=255,G=255,B=0,A=255)
	RedSkin=Texture'<? echo($packageName); ?>.Drones.DroneTexRed'
	RedTrail=(R=255,G=0,B=0,A=255)
	BlueSkin=Texture'<? echo($packageName); ?>.Drones.DroneTexBlue'
	BlueTrail=(R=0,G=0,B=255,A=255)
	GreenSkin=Texture'<? echo($packageName); ?>.Drones.DroneTexGreen'
	GreenTrail=(R=0,G=255,B=0,A=255)
	GoldSkin=Texture'<? echo($packageName); ?>.Drones.DroneTex'
	GoldTrail=(R=255,G=224,B=0,A=255)
	bAlwaysRelevant=True
	bReplicateInstigator=True
	Physics=PHYS_Projectile
	RemoteRole=ROLE_SimulatedProxy
	AmbientSound=Sound'WeaponSounds.LinkGun.LinkGunProjectile'
	LifeSpan=9999.000000
	DrawScale=2.500000
	bUnlit=True
	bDisturbFluidSurface=True
	SoundVolume=255
	SoundRadius=50.000000
	CollisionRadius=20.000000
	CollisionHeight=20.000000
	bCollideActors=True
	bCollideWorld=True
	bUseCylinderCollision=True
	bBounce=True
	bFixedRotationDir=True
	RotationRate=(Yaw=24000)
	DesiredRotation=(Yaw=30000)
}
