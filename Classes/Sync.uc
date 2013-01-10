/*
	I'm sick of adding functions to the RPGPlayerReplicationInfo for things like
	projectile speeds (Force).
	
	This is a new solution attempt, an Actor that will be spawned on all clients,
	just to transmit certain information to them.
	
	ClientFunction is to do whatever is supposed to do on the client, all information
	required can simply be replicated.
*/
class Sync extends Actor; //TODO: Make ReplicationInfo

var float LifeTime;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		LifeTime;
}

simulated event Tick(float dt)
{
	Super.Tick(dt);

	LifeTime -= dt;
	if(LifeTime <= 0.0f || (Role == ROLE_Authority && ShouldDestroy()))
	{
		Destroy();
		return;
	}

	if(Role == ROLE_Authority)
		return;
	
	if(ClientFunction())
		Destroy();
}

//return true if this should be destroyed (client)
simulated function bool ClientFunction();

//return true if this should be destroyed (server)
function ShouldDestroy();

defaultproperties
{
	LifeTime=5.00
	DrawType=DT_None
	bNetTemporary=True
	bReplicateInstigator=True
	bReplicateMovement=False
	bOnlyRelevantToOwner=False
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
