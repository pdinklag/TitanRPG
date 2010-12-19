class RPGWeaponFadeEffect extends WeaponFadeEffect;

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();

	//Disable, they are bugged and barely fixable
	Emitters[0].Disabled = true;
	Emitters[1].Disabled = true;
}

defaultproperties
{
}
