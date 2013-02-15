class Effect_Vorpal extends RPGInstantEffect;

function DoEffect()
{
	Instigator.Died(EffectCauser, class'DamTypeVorpal', Instigator.Location);
}

defaultproperties
{
	EffectSound=Sound'WeaponSounds.Misc.instagib_rifleshot'
	xEmitterClass=class'RocketExplosion'
	EffectMessageClass=class'EffectMessage_Vorpal'
}
