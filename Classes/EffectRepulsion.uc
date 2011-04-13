class EffectRepulsion extends EffectKnockback;

defaultproperties
{
	bAllowOnSelf=False
	bAllowOnVehicles=False

	DamageType=class'DamTypeRepulsion'

	EffectSound=None
	EffectOverlay=Shader'<? echo($packageName); ?>.Overlays.RedShader'
	EffectMessageClass=class'EffectMessageRepulsion'
}
