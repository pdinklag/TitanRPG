class Effect_NullEntropy extends RPGEffect;

replication
{
	unreliable if(Role == ROLE_Authority)
		ClientFixLocation;
}

simulated function ClientFixLocation(vector NullLocation)
{
	if(Instigator != None)
	{
		Instigator.SetLocation(NullLocation);
		Instigator.SetPhysics(PHYS_NONE);
	}
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		
		Instigator.SetPhysics(PHYS_None);
	}

	event Tick(float dt)
	{
		Super.Tick(dt);
		
		if(!bPendingDelete)
		{
			if(Instigator.Physics != PHYS_NONE)
				Instigator.SetPhysics(PHYS_NONE);
		}
	}
	
	function Timer()
	{
		Super.Timer();
		ClientFixLocation(Instigator.Location);
	}
	
	function EndState()
	{
		if(Instigator != None && Instigator.Physics == PHYS_None)
			Instigator.SetPhysics(PHYS_Falling);
		
		Super.EndState();
	}
}

defaultproperties
{
	bAllowOnFlagCarriers=False
	bAllowOnVehicles=False

	EffectSound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
	EffectOverlay=Shader'MutantSkins.Shaders.MutantGlowShader'
	EffectMessageClass=class'EffectMessage_NullEntropy'
}
