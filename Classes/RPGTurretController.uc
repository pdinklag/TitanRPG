/*
	Code base taken from mcgRPG - original author unknown.
*/
class RPGTurretController extends ASSentinelController;

var Controller Master; //player who spawned this turret

function Possess(Pawn aPawn)
{
	Super(TurretController).Possess(aPawn);

	if(IsSpawnCampProtecting())
	{
		Skill = 10;
		FocusLead = 0;
		Pawn.RotationRate = Pawn.default.RotationRate * 4;
	}
	else
	{
		AcquisitionYawRate = 20000;
	}
	
	Enable('Tick');
}

event Tick(float dt)
{
    local Pawn P;
    local Controller C;
	
    if(Pawn == None || Pawn.Controller != Self || Pawn.bPendingDelete)
    {
        Destroy();
        return;
    }
	
	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		P = C.Pawn;
		if(
			C.bIsPlayer &&
			P != None &&
			P != Pawn &&
			!SameTeamAs(C) &&
			P.Health > 0 &&
			VSize(P.Location - Pawn.Location) <= Pawn.SightRadius &&
			CanSee(P)
		)
		{
			SeePlayer(P);
			break;
		}
	}
}

auto state Searching
{
	function ScanRotation()
	{
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
	
    Begin:
		ScanRotation();
		FocalPoint = Pawn.Location + 1000 * vector(DesiredRotation);
		Sleep(GetScanDelay());
		Goto('Begin');
}

state Closing
{
	event BeginState()
	{
        Disable('Tick');
	}

	event EndState()
	{
        Enable('Tick');
	}
	
	event Tick(float d);
}

state Opening
{
	event BeginState()
	{
        Disable('Tick');
	}

	event EndState()
	{
        Enable('Tick');
	}
	
	event Tick(float dt);
}

state Engaged
{
	event BeginState()
	{
        Disable('Tick');
		Super.BeginState();
	}

	event EndState()
	{
        Enable('Tick');
	}
	
	event Tick(float dt);
}

state Sleeping
{
	function Awake()
	{
		LastRotation = Rotation;
		ASVehicle_Sentinel(Pawn).Awake();
		GotoState('Opening');
	}
}

function bool IsSpawnCampProtecting()
{
    return (ASVehicle_Sentinel(Pawn) != None);
}

function bool IsTargetRelevant(Pawn Target)
{
	return
	(
		Pawn != None &&
		Target != None &&
		Target != Pawn &&
		Target.Controller != None &&
		!SameTeamAs(Target.Controller) &&
		Target.Health > 0 &&
		VSize(Target.Location - Pawn.Location) <= Pawn.SightRadius * 1.25
	);
}

defaultproperties
{
}
