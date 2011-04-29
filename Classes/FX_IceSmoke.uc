class FX_IceSmoke extends RocketExplosion;

simulated event PostBeginPlay()
{
	local PlayerController PC;
	
	PC = Level.GetLocalPlayerController();
	if
	(
		PC != None && 
		(
			PC.ViewTarget == None || 
			VSize(PC.ViewTarget.Location - Location) > 5000
		)
	)
	{
		LightType = LT_None;
		bDynamicLight = false;
	}
	else 
	{
		Spawn(class'RocketSmokeRing');
		if (Level.bDropDetail)
			LightRadius = 7;	
	}
	//dont call super. The Super classes's postbeginplay is messed up.
}

defaultproperties
{
	LightHue=209
	LightSaturation=33
	RemoteRole=ROLE_SimulatedProxy
	DrawScale=0.000100
}
