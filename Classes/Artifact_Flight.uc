class Artifact_Flight extends RPGArtifact;

var Emitter FlightTrail;
var localized string NotInVehicleMessage;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
	
		if (PlayerController(Instigator.Controller) != None)
			Instigator.Controller.GotoState('PlayerFlying');
		else
			Instigator.SetPhysics(PHYS_Flying);
			
		FlightTrail = Instigator.spawn(class'FX_Flight', Instigator);
	}
	
	event Tick(float dt)
	{
		if(Instigator.Controller != None)
		{
			//Update the state / physics every tick, this allows translocating while flying -pd
			if (PlayerController(Instigator.Controller) != None && !PlayerController(Instigator.Controller).IsInState('PlayerFlying'))
				Instigator.Controller.GotoState('PlayerFlying');
			else
				Instigator.SetPhysics(PHYS_Flying);

			Super.Tick(dt);
		}
	}

	function EndState()
	{
		if(Instigator != None && Instigator.Controller != None && Instigator.DrivenVehicle == None)
		{
			//water fix - mostly copied from PlayerController.EnterStartState() ~pd
			if(Instigator.PhysicsVolume.bWaterVolume)
			{
				if(Instigator.HeadVolume.bWaterVolume)
					Instigator.BreathTime = Instigator.UnderWaterTime;
				
				Instigator.SetPhysics(PHYS_Swimming);
				Instigator.Controller.GotoState(Instigator.WaterMovementState);
			}
			else
			{
				Instigator.SetPhysics(PHYS_Falling);
				Instigator.Controller.GotoState(Instigator.LandMovementState);
			}
		}
		
		if(FlightTrail != None)
			FlightTrail.Kill();
			
		Super.EndState();
	}
}

defaultproperties
{
	MinActivationTime=1.000000
	bAllowInVehicle=False
	CostPerSec=4
	HudColor=(B=255,G=0,R=128)
	ArtifactID="Flight"
	Description="Makes you fly."
	PickupClass=Class'ArtifactPickup_Flight'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Flight'
	ItemName="Flight"
}
