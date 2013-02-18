class FriendlyPawnReplicationInfo extends ReplicationInfo;

var Pawn Pawn;
var PlayerReplicationInfo Master;

var Interaction_Global Interaction; //client

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Master, Pawn;
}

simulated event PostNetBeginPlay()
{
	local int i;
	local PlayerController PC;

	Super.PostNetBeginPlay();
	
	if(Level.NetMode != NM_DedicatedServer)
	{
		PC = Level.GetLocalPlayerController();
		if(PC != None)
		{
			for(i = 0; i < PC.Player.LocalInteractions.Length; i++)
			{
				if(PC.Player.LocalInteractions[i].IsA('Interaction_Global'))
				{
					Interaction = Interaction_Global(PC.Player.LocalInteractions[i]);
					Interaction.AddFriendlyPawn(Self);
					break;
				}
			}
		}
	}
}

simulated event Tick(float dt)
{
	Super.Tick(dt);

	if(Role == ROLE_Authority)
	{
		if(Master == None || Pawn == None || Pawn.Health <= 0)
			Destroy();
	}
}

simulated event Destroyed()
{
	if(Interaction != None)	
		Interaction.RemoveFriendlyPawn(Self);

	Super.Destroyed();
}

defaultproperties
{
	NetUpdateFrequency=1.00
}
