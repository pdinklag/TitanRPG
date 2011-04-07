class EffectKnockback extends RPGEffect;

var vector Momentum;
var class<DamageType> DamageType;

state Activated
{
	function BeginState()
	{
		Super.BeginState();

		/*
			if they're walking, I need to bump them up 
			in the air a bit or they won't be knocked back 
			on no momentum weapons.
		*/
		if(Instigator.Physics == PHYS_Walking)
			Instigator.SetLocation(Instigator.Location + vect(0, 0, 10));

		if(
			Instigator.Physics != PHYS_Walking && 
			Instigator.Physics != PHYS_Falling &&
			Instigator.Physics != PHYS_Hovering)
		{
			Instigator.SetPhysics(PHYS_Hovering);
		}
		
		//see ya
		Instigator.TakeDamage(0, EffectCauser.Pawn, Instigator.Location, Momentum, DamageType);
	}

	event Tick(float dt)
	{
		Super.Tick(dt);
		
		if(!bPendingDelete)
		{
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
	
	function EndState()
	{
		if(Instigator != None && Instigator.Physics != PHYS_Walking && Instigator.Physics != PHYS_Falling)
			Instigator.SetPhysics(PHYS_Falling);
		
		Super.EndState();
	}
}

defaultproperties
{
	//DamageType=class'DamTypeKnockback'
	DamageType=class'fell'

	bAllowOnFlagCarriers=False

	EffectSound=Sound'WeaponSounds.Misc.ballgun_launch'
	EffectOverlay=Shader'<? echo($packageName); ?>.Overlays.RedShader'
	EffectMessageClass=class'EffectMessageKnockback'
}
