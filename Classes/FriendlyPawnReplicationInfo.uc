class FriendlyPawnReplicationInfo extends ReplicationInfo;

var Pawn Pawn;

//replicated
var PlayerReplicationInfo Master;

//we can only replicate this info because the Pawn itself may become irrelevant
var class<Pawn> PawnClass;
var vector PawnLocation;
var int PawnHealth;
var float PawnHeight;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Master;
	
	reliable if(Role == ROLE_Authority && bNetDirty)
		Pawn, PawnLocation, PawnHealth, PawnClass, PawnHeight;
}

simulated event Tick(float dt)
{
	Super.Tick(dt);

	if(Role == ROLE_Authority)
	{
		if(Master == None || Pawn == None || Pawn.Health <= 0)
		{
			Destroy();
		}
		else
		{
			PawnLocation = Pawn.Location;
			PawnClass = Pawn.class;
			PawnHealth = Pawn.Health;
			PawnHeight = Pawn.CollisionHeight * Pawn.DrawScale;
		}
	}
}

defaultproperties
{
	NetUpdateFrequency=16.00
}
