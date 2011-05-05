class RPGReplicationInfo extends ReplicationInfo;

const MAX_ARTIFACTS = 63;

var int NumAbilities;
var class<RPGArtifact> Artifacts[MAX_ARTIFACTS];

//Test
var string ReplicatedString;

//Client
var Interaction Interaction;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Artifacts, NumAbilities, ReplicatedString;
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
		string(class'RPGGlobalInteraction'), PC.Player);
}

simulated event PostBeginPlay()
{
	local int i;
	
	Super.PostBeginPlay();

	if(Role == ROLE_Authority)
	{
		for(i = 0; i < 499; i++)
			ReplicatedString $= "A"; //499
	}
}

simulated event PostNetBeginPlay()
{
	local int i;

	Super.PostNetBeginPlay();
	
	if(Role < ROLE_Authority);
		Log(Self @ "INITIAL ReplicatedString length:" @ Len(ReplicatedString));

	if(Role < ROLE_Authority && Interaction == None)
	{
		ClientSetup(Level.GetLocalPlayerController());
		//Disable('Tick');
	}
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
		//Disable('Tick');
	}
	
	Log(Self @ "ReplicatedString length:" @ Len(ReplicatedString));
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
