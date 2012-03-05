class Artifact_Magnet extends RPGArtifact;

var Emitter FlightTrail;
var int Retry;

const MSG_OnlySolidGround = 0x1000;

var localized string OnlySolidGroundText;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_OnlySolidGround:
			return default.OnlySolidGroundText;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	if(!Super.CanActivate())
		return false;

	if(Instigator.Base == None ||
		Instigator.Physics != PHYS_Walking ||
		(Instigator.Base.IsA('BlockingVolume') && !Instigator.Base.bBlockZeroExtentTraces))
	{
		Msg(MSG_OnlySolidGround);
		return false;
	}

	return true;
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();
	
		if (PlayerController(Instigator.Controller) != None)
			Instigator.Controller.GotoState('PlayerSpidering');
		else
			Instigator.SetPhysics(PHYS_Spider);
	
		FlightTrail = Instigator.spawn(class'FX_Flight', Instigator);
		Retry = 0;
		SetTimer(0.15, true);
	}

	function Timer()
	{
		if (Instigator.Physics != PHYS_Spider)
		{
			retry++;
			if(retry > 2)
			{
				bActive = false;
				GotoState('');
			}
		}
		else if (Instigator.Base != None )
		{
			if(Instigator.Base.IsA('BlockingVolume') && !Instigator.Base.bBlockZeroExtentTraces)
			{
				Retry++;
				if(Retry > 2)
				{
					bActive = false;
					GotoState('');
				}
			}
		}
		else
		{
			Retry = 0;
		}
	}

	function EndState()
	{
		SetTimer(0, true);
		Retry = 0;
		
		if(Instigator != None && Instigator.DrivenVehicle == None)
		{
			Instigator.SetPhysics(PHYS_Falling);
			Instigator.Controller.GotoState(Instigator.LandMovementState);
		}

		if(FlightTrail != None)
			FlightTrail.Kill();
			
		Super.EndState();
	}
}

defaultproperties
{
	bAllowInVehicle=False
	MinActivationTime=1.000000
	OnlySolidGroundText="You need to be on solid ground."
	CostPerSec=2
	HudColor=(B=128,R=128)
	ArtifactID="Magnet"
	Description="Allows you to walk on walls."
	PickupClass=Class'ArtifactPickup_Magnet'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.magnet'
	ItemName="Magnet"
}
