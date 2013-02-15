class Effect_Disco extends RPGEffect;

var RPGPlayerReplicationInfo RPRI;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
        
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
        if(RPRI != None) {
            RPRI.bDiscoMode = true;
            RPRI.NetUpdateTime = Level.TimeSeconds - 1;
        }
	}

	function EndState()
	{
        if(RPRI != None) {
            RPRI.bDiscoMode = false;
            RPRI.NetUpdateTime = Level.TimeSeconds - 1;
        }
    
		Super.EndState();
	}
}

defaultproperties
{
	bAllowOnFlagCarriers=True
	bAllowOnVehicles=True

	EffectOverlay=Shader'TitanRPG.Disco.IonSphere'
	//TODO: EffectSound=Sound'Slaughtersounds.Machinery.Heavy_End'
	
	EffectMessageClass=class'EffectMessage_Disco'
}
