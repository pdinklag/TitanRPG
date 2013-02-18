class RPGReplicationInfo extends ReplicationInfo;

const MAX_ARTIFACTS = 63;

var int NumAbilities;
var class<RPGArtifact> Artifacts[MAX_ARTIFACTS];

//Client
var Interaction Interaction;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Artifacts, NumAbilities;
}

static function RPGReplicationInfo Get(LevelInfo Level)
{
	local RPGReplicationInfo RRI;
	
	foreach Level.DynamicActors(class'RPGReplicationInfo', RRI)
		return RRI;
	
	return None;
}

simulated function ClientSetup(PlayerController PC)
{
	Interaction = PC.Player.InteractionMaster.AddInteraction(
		string(class'Interaction_Global'), PC.Player);
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if(Role < ROLE_Authority && Interaction == None)
		ClientSetup(Level.GetLocalPlayerController());
}

simulated event Tick(float dt)
{
	local PlayerController PC;

	if(Level.NetMode == NM_Standalone)
	{
		PC = Level.GetLocalPlayerController();
		if(PC != None)
		{
			ClientSetup(PC);
			Disable('Tick');
		}
	}
	else
	{
		Disable('Tick');
	}
}

simulated event Destroyed()
{
	if(Interaction != None)
		Interaction.Master.RemoveInteraction(Interaction);
	
	Interaction = None;
	Super.Destroyed();
}

defaultproperties
{
}
