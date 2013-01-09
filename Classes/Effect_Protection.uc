class Effect_Protection extends RPGEffect;

defaultproperties
{
    bHarmful=False
	bAllowStacking=False
    
    //TODO status icon
    TimerInterval=0 //no message repeat
	
	EffectSound=Sound'TitanRPG.SoundEffects.Protection'
	EffectMessageClass=class'EffectMessage_Protection'
    StatusIconClass=class'StatusIcon_Protection'
}
