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
        }
	}

	function EndState()
	{
        if(RPRI != None) {
            RPRI.bDiscoMode = false;
        }
    
		Super.EndState();
	}
}

defaultproperties
{
	bAllowOnFlagCarriers=True
	bAllowOnVehicles=True

	EffectOverlay=FinalBlend'TitanRPG.Disco.IonSphereFinal'
	//TODO: EffectSound=Sound'Slaughtersounds.Machinery.Heavy_End'
	
	EffectMessageClass=class'EffectMessage_Disco'
}
