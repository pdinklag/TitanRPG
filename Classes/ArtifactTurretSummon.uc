class ArtifactTurretSummon extends ArtifactTurretSummonBase;

struct TurretTypeStruct
{
	var class<Vehicle> TurretClass;
	var int Cost;
	
	//Preview
	var StaticMesh StaticMesh;
	var float DrawScale;
};
var config array<TurretTypeStruct> TurretTypes;

var int PickedTurret;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientShowMenu, ClientClearTurretTypes, ClientReceivePickableTurret;

	reliable if(Role < ROLE_Authority)
		ServerPickTurret;
}

simulated function int PickBest()
{
	local int i, Cost, Best, BestCost;
	
	Best = -1;
	BestCost = 0;
	
	for(i = 0; i < TurretTypes.Length; i++)
	{
		Cost = TurretTypes[i].Cost;
		if(Cost <= Instigator.Controller.Adrenaline && Cost > BestCost)
		{
			Best = i;
			BestCost = Cost;
		}
	}
	return Best;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int i;

	Super.GiveTo(Other, Pickup);
	
	if(Level.NetMode == NM_DedicatedServer)
	{
		ClientClearTurretTypes();
		for(i = 0; i < TurretTypes.Length; i++)
			ClientReceivePickableTurret(TurretTypes[i]);
	}
}

simulated function ClientClearTurretTypes()
{
	if(TurretTypes.Length > 0)
		TurretTypes.Remove(0, TurretTypes.Length);
}

simulated function ClientReceivePickableTurret(TurretTypeStruct Type)
{
	TurretTypes[TurretTypes.Length] = Type;
}

simulated function ClientShowMenu()
{
	class'SelectionMenu_ConstructTurret'.static.ShowFor(Self);
}

function ServerPickTurret(int i)
{
	PickedTurret = i;
	
	if(i >= 0)
	{
		TurretType = TurretTypes[i].TurretClass;
		CostPerSec = TurretTypes[i].Cost;
		
		Activate();
	}
}

function bool CanActivate()
{
	local bool b;
	
	b = Super.CanActivate();
	if(PickedTurret >= 0 && !b)
	{
		PickedTurret = -1;
		CostPerSec = 0;
	}
	
	return b;
}

state Activated
{
	function BeginState()
	{
		if(PickedTurret >= 0)
		{
			Super.BeginState();
		}
		else
		{
			GotoState('');
		
			if(Instigator.Controller.IsA('PlayerController'))
				ClientShowMenu();
			else
				ServerPickTurret(PickBest());
		}
	}
	
	function EndState()
	{
		if(PickedTurret >= 0)
			Super.EndState();
		
		PickedTurret = -1;
		CostPerSec = 0;
	}
}

defaultproperties
{
	PickedTurret=-1

	ArtifactID="TurretSummon"
	Description="Constructs a defensive turret."
	ItemName="Turret Constructor"
	PickupClass=Class'ArtifactPickupTurretSummon'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.TurretSummon'
	HudColor=(B=160,G=160,R=160)
	CostPerSec=10
	Cooldown=0
	TurretTypes(0)=(TurretClass=class'UT2k4Assault.ASVehicle_Sentinel_Floor',Cost=100,StaticMesh=StaticMesh'AS_Weapons_SM.FloorTurretStaticEditor',DrawScale=0.125)
}
