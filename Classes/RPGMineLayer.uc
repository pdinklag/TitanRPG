class RPGMineLayer extends ONSMineLayer
	HideDropDown
	CacheExempt;

simulated function NewDrawWeaponInfo(Canvas Canvas, float YPos)
{
	local RPGPlayerReplicationInfo RPRI;
	local int OldCurrentMines, OldMaxMines;
	
	//life made easy
	OldCurrentMines = CurrentMines;
	OldMaxMines = MaxMines;
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
	if(RPRI != None)
	{
		CurrentMines = RPRI.NumMines;
		MaxMines = RPRI.MaxMines;
	}
	
	Super.NewDrawWeaponInfo(Canvas, YPos);
	
	CurrentMines = OldCurrentMines;
	MaxMines = OldMaxMines;
}

defaultproperties
{
	FireModeClass(0)=class'RPGMineThrowFire'
	FireModeClass(1)=class'RPGMineLayerAltFire'
	PickupClass=class'RPGMineLayerPickup'
}
