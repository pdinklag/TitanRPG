class Sync_ONSWeaponRotSpeed extends Sync;

var ONSWeapon Target;
var float RotationsPerSecond;

var bool bFirstTick;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Target, RotationsPerSecond;
}

simulated function bool ClientFunction()
{
	if(bFirstTick)
	{
		bFirstTick = false;
		return false;
	}
	else
	{
		Target.RotationsPerSecond = RotationsPerSecond;
		return true;
	}
}

defaultproperties
{
	bFirstTick=True
	LifeTime=2.00
}
