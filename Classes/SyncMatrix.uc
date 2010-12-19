class SyncMatrix extends SyncProjectileSpeed;

//Needs to be replicated to sync projectiles that are currently accelerated
var vector ProjVelocity, ProjLocation;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		ProjVelocity, ProjLocation;
}

simulated function bool ClientFunction()
{
	Super.ClientFunction();

	if(Proj != None)
	{
		Proj.SetLocation(ProjLocation);
		Proj.Velocity = ProjVelocity;
		Proj.Spawn(class'MatrixTrail', Proj,, Proj.Location, Proj.Rotation).SetBase(Proj);
	}
	
	return true;
}

defaultproperties
{
}
