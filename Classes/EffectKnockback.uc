class EffectKnockback extends RPGEffect;

function StartEffect()
{
	Super.StartEffect();

	if(
		Instigator.Physics != PHYS_Walking && 
		Instigator.Physics != PHYS_Falling &&
		Instigator.Physics != PHYS_Hovering)
	{
		Instigator.SetPhysics(PHYS_Hovering);
	}
}

function StopEffect()
{
	if(Instigator != None && Instigator.Physics != PHYS_Walking && Instigator.Physics != PHYS_Falling)
		Instigator.SetPhysics(PHYS_Falling);
}

state Active
{
	event Tick(float dt)
	{
		Super.Tick(dt);
		
		if(!bPendingDelete)
		{
			if(Instigator != None && Instigator.Base != None)
			{
				Destroy();
				return;
			}
			
			if(
				!bAllowOnFlagCarriers &&
				Instigator.PlayerReplicationInfo != None &&
				Instigator.PlayerReplicationInfo.HasFlag != None)
			{
				//exploit fix
				Instigator.Velocity = vect(0, 0, 0);
				Destroy();
			}
		}
	}
}

defaultproperties
{
	Modifier=1.0
	bAllowOnFlagCarriers=False

	EffectSound=Sound'WeaponSounds.Misc.ballgun_launch'
	EffectOverlay=Shader'<? echo($packageName); ?>.Overlays.RedShader'
	EffectMessageClass=class'EffectMessageKnockback'
}
