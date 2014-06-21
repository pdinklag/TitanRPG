/*
	Code base taken from mcgRPG - original author unknown.
*/
class FriendlyTurretController extends ASSentinelController
	config(TitanRPG);

var Controller Master; //player who spawned this turret
var RPGPlayerReplicationInfo MasterRPRI;
var int TeamNum;

var config float SleepDelay;
var config float FireRate;

var config float DefaultSightRadius;
var config float DefaultSkill;

var FriendlyPawnReplicationInfo FPRI;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	FPRI = Spawn(class'FriendlyPawnReplicationInfo');
}

function SetMaster(Controller NewMaster) {
	Master = NewMaster;
    MasterRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Master);
	FPRI.Master = Master.PlayerReplicationInfo;
    
	if(Master.PlayerReplicationInfo != None && Master.PlayerReplicationInfo.Team != None) {
		TeamNum = Master.PlayerReplicationInfo.Team.TeamIndex;
	} else {
		TeamNum = 255;
    }
}

simulated function int GetTeamNum() {
	return TeamNum;
}

function Possess(Pawn aPawn)
{
    Super(TurretController).Possess(aPawn);

    FPRI.Pawn = aPawn;

    //Defaults, controlled by abiltiies
    aPawn.SightRadius = DefaultSightRadius;
    InitializeSkill(DefaultSkill);
    
    if(aPawn.Weapon != None) {
        //TODO possibly modify fire rate
    }
    
	Enable('Tick');
}

function InitializeSkill(int x) {
    Skill = x;
    if(Skill > 3) {
        FocusLead = (0.07 * FMin(Skill, 7)) / 10000; 
    }
}

event Tick(float dt) {
    Super.Tick(dt);
    
    if(Pawn == None || Pawn.Controller != Self || Pawn.bPendingDelete) {
        Destroy();
        return;
    }

	//if I don't have a master or he switched teams, I should die
    if(
        Master == None ||
        Master.PlayerReplicationInfo == None ||
        Master.PlayerReplicationInfo.bOnlySpectator ||
        !SameTeamAs(Master)
    ) {
        Pawn.Suicide();
    } else if(MasterRPRI != None) {
        //if my master died, test if I should as well
        if(MasterRPRI.bTurretsDie && (Master.Pawn == None || Master.Pawn.Health <= 0)) {
            Pawn.Suicide();
        }
    }
}

state Searching
{
    event BeginState() {
        Super.BeginState();
        SetTimer(SleepDelay, false);
    }
    
    function Timer() {
        GotoState('Closing');
    }
    
    event EndState() {
        SetTimer(0, false);
        Super.EndState();
    }

	function ScanRotation() {
		local Rotator OldDesired;

		if(Pawn == None || Pawn.Controller != Self || Pawn.bPendingDelete)
		{
			Destroy();
			return;
		}

		if(ASTurret_LinkTurret(Pawn) == None)
		{
			Super(TurretController).ScanRotation();
			return;
		}

		OldDesired = DesiredRotation;
		DesiredRotation = ASTurret_LinkTurret(Pawn).OriginalRotation;
		DesiredRotation.Yaw = DesiredRotation.Yaw + 8192;

		if((DesiredRotation.Yaw & 65535) == (OldDesired.Yaw & 65535))
			DesiredRotation.Yaw -= 16384;
	}
    
    event Tick(float dt) {
        local Pawn P;

        Global.Tick(dt);
        
        foreach Pawn.VisibleCollidingActors(class'Pawn', P, Pawn.SightRadius) {
            if(CanSee(P)) {
                SeePlayer(P);
            }

            if(Enemy == P) {
                break;
            }
        }
    }
	
    Begin:
		ScanRotation();
		FocalPoint = Pawn.Location + 1000 * vector(DesiredRotation);
		Sleep(GetScanDelay());
		Goto('Begin');
}

state Closing {
	event Tick(float dt) {
        Global.Tick(dt);
    }
}

state Opening {
	event Tick(float dt) {
        Global.Tick(dt);
    }
}

state Engaged {
	event Tick(float dt) {
        Global.Tick(dt);
    }
}

auto state Sleeping {
    event Tick(float dt) {
        local Pawn P;

        Global.Tick(dt);
        
        foreach Pawn.VisibleCollidingActors(class'Pawn', P, Pawn.SightRadius) {
            SeePlayer(P);

            if(Enemy == P) {
                break;
            }
        }
    }

	function Awake() {
		LastRotation = Rotation;
		ASVehicle_Sentinel(Pawn).Awake();
		GotoState('Opening');
	}
}

function bool IsSpawnCampProtecting() {
    return false;
}

function bool IsTargetRelevant(Pawn Target) {
    if(Target == None || Target == Pawn || (Master != None && Target == Master.Pawn) || Target.Health <= 0) {
        //not valid target
        return false;
    }
    
    if(SameTeamAs(Target.Controller)) {
        //same team
        return false;
    }
    
    if(Target.IsA('Vehicle') && (Vehicle(Target).Team == TeamNum || (Vehicle(Target).IsVehicleEmpty() && !Vehicle(Target).bAutoTurret))) {
        //empty vehicle or same team
        return false;
    }
    
    if(VSize(Target.Location - Pawn.Location) > Pawn.SightRadius * 1.15) {
        //too far away
        return false;
    }

    return true;
}

defaultproperties {
    FireRate=0.5
    SleepDelay=10
    
    DefaultSightRadius=2048
    DefaultSkill=7
}
