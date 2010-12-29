class FriendlyPawnReplicationInfo extends ReplicationInfo;

var Pawn Pawn;
var PlayerReplicationInfo Master;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Pawn, Master;
}

simulated event Tick(float dt)
{
	Super.Tick(dt);

	if(Role == ROLE_Authority && (Master == None || Pawn == None || Pawn.Health <= 0))
		Destroy();
}

defaultproperties
{
	NetUpdateFrequency=1.00
}
