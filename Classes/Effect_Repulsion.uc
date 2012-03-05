class Effect_Repulsion extends Effect_Knockback;

defaultproperties
{
	bAllowOnSelf=False
	bAllowOnVehicles=False

	DamageType=class'DamTypeRepulsion'

	EffectSound=None
	EffectOverlay=Shader'TitanRPG.Overlays.RedShader'
	EffectMessageClass=class'EffectMessage_Repulsion'
}
