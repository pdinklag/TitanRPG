class EffectVorpal extends RPGInstantEffect;

function DoEffect()
{
	Instigator.Died(EffectCauser, class'DamTypeVorpal', Instigator.Location);
}

defaultproperties
{
	//EffectOverlay=Shader'<? echo($packageName); ?>.Overlays.GreyShader'
	EffectSound=Sound'WeaponSounds.Misc.instagib_rifleshot'
	EmitterClass=class'RocketExplosion'
	
	EffectMessageClass=class'EffectMessageVorpal'
}
