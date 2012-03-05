class Effect_Freeze extends RPGEffect;

//saved values for unapply
var float JumpZ;
var float DodgeSpeedZ;
var float DodgeSpeedFactor;
var bool bCanDoubleJump;
var bool bCanWallDodge;
var bool bCanDodgeDoubleJump;
var int MaxMultiJump;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		
		//store values
		JumpZ = Instigator.JumpZ;
		DodgeSpeedZ = Instigator.DodgeSpeedZ;
		DodgeSpeedFactor = Instigator.DodgeSpeedFactor;
		bCanDoubleJump = Instigator.bCanDoubleJump;
		bCanWallDodge = Instigator.bCanWallDodge;
		
		if(Instigator.IsA('xPawn'))
		{
			bCanDodgeDoubleJump = xPawn(Instigator).bCanDodgeDoubleJump;
			MaxMultiJump = xPawn(Instigator).MaxMultiJump;
		}
		
		//apply
		if(Modifier != 0)
			class'Util'.static.PawnScaleSpeed(Instigator, Modifier);

		Instigator.JumpZ = -0.1; //prevents playing a very loud landing sound
		Instigator.DodgeSpeedZ = 0;
		Instigator.DodgeSpeedFactor = 0;
		Instigator.bCanDoubleJump = false;
		Instigator.bCanWallDodge = false;

		if(Instigator.IsA('xPawn'))
		{
			xPawn(Instigator).bCanDodgeDoubleJump = false;
			xPawn(Instigator).MultiJumpRemaining = 0;
			xPawn(Instigator).MaxMultiJump = 0;
		}
	}

	function EndState()
	{
		//unapply
		if(Modifier != 0)
			class'Util'.static.PawnScaleSpeed(Instigator, 1.f / Modifier);

		Instigator.JumpZ = JumpZ;
		Instigator.DodgeSpeedZ = DodgeSpeedZ;
		Instigator.DodgeSpeedFactor = DodgeSpeedFactor;
		Instigator.bCanDoubleJump = bCanDoubleJump;
		Instigator.bCanWallDodge = bCanWallDodge;
			
		if(Instigator.IsA('xPawn'))
		{
			xPawn(Instigator).bCanDodgeDoubleJump = bCanDodgeDoubleJump;
			xPawn(Instigator).MultiJumpRemaining = MaxMultiJump;
			xPawn(Instigator).MaxMultiJump = MaxMultiJump;
		}
		
		Super.EndState();
	}
}

defaultproperties
{
	bAllowOnFlagCarriers=False
	bAllowOnVehicles=False

	EffectOverlay=Shader'TitanRPG.Overlays.GreyShader'
	EffectSound=Sound'Slaughtersounds.Machinery.Heavy_End'
	xEmitterClass=class'FX_IceSmoke'
	
	EffectMessageClass=class'EffectMessage_Freeze'
}
