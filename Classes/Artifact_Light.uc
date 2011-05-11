class Artifact_Light extends RPGArtifact hidedropdown;

var FX_PlayerLight Light;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		
		if(Light == None)
		{
			Light = Spawn(class'FX_PlayerLight', Instigator, , Instigator.Location);
			Light.SetBase(Instigator);
			Light.LightHue = 40;
			Light.LightSaturation = 224;
			Light.LightBrightness = 192;
			Light.LightChanged();
		}
	}
	
	function EndState()
	{
		if(Light != None)
			Light.Destroy();
		
		Super.EndState();
	}
}

defaultproperties
{
	CostPerSec=1
	MinActivationTime=1.000000
	HudColor=(B=255,G=192,R=64)
	Description="Creates a light around you."
	//PickupClass=Class'ArtifactInvulnerabilityPickup'
	IconMaterial=Texture'Engine.S_Emitter'
	ItemName="Light"
	ArtifactID="Light"
}
