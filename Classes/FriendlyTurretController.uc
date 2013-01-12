/*
	Code base taken from mcgRPG - original author unknown.
*/
class FriendlyTurretController extends ASSentinelController;

var Controller Master; //player who spawned this turret
var int TeamNum;

var float SleepDelay;

var FriendlyPawnReplicationInfo FPRI;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	FPRI = Spawn(class'FriendlyPawnReplicationInfo');
}

function SetMaster(Controller NewMaster) {
	Master = NewMaster;
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
    aPawn.SightRadius = 8192;
    
    //TODO make rotation rate, skill and sight radius abilities

	//AcquisitionYawRate = 20000;
	Enable('Tick');
}

function SetSkill(int x) {
    Skill = x;
    if(Skill > 3) {
        FocusLead = (0.07 * FMin(Skill, 7)) / 10000; 
    }
}

event Tick(float dt) {
	//if I don't have a master or it switched teams, I should die
	if(
		Master == None ||
		Master.Pawn == None || 
		Master.Pawn.Health <= 0 ||
		Master.PlayerReplicationInfo == None ||
		Master.PlayerReplicationInfo.bOnlySpectator ||
		!SameTeamAs(Master)
	)
	{
        if(Pawn != None) {
            Pawn.Suicide();
        }
        
        Destroy();
		return;
	}
	
    if(Pawn == None || Pawn.Controller != Self || Pawn.bPendingDelete) {
        Destroy();
        return;
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
        local Controller C;
    
        Global.Tick(dt);
    
        for(C = Level.ControllerList; C != None; C = C.NextController) {
            P = C.Pawn;
            if(
                C.bIsPlayer &&
                P != None &&
                P != Pawn &&
                P != Master.Pawn &&
                !SameTeamAs(C) &&
                P.Health > 0 &&
                VSize(P.Location - Pawn.Location) <= Pawn.SightRadius &&
                CanSee(P)
            ) {
                SeePlayer(P);
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
    local bool bRelevant;

	bRelevant = (
		Pawn != None &&
		Target != None &&
		Target != Pawn &&
        Target != Master.Pawn &&
		Target.Controller != None &&
		!SameTeamAs(Target.Controller) &&
		Target.Health > 0 &&
		VSize(Target.Location - Pawn.Location) <= Pawn.SightRadius * 1.25
	);
    
    if(!bRelevant && Target.IsA('Monster')) {
        Log("Irrelevant target:" @ Target);
    }
    
    return bRelevant;
}

defaultproperties {
    SleepDelay=10;
}
