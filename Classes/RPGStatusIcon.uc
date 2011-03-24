class RPGStatusIcon extends ReplicationInfo
	abstract;

var Material IconMaterial;

var RPGPlayerReplicationInfo RPRI;
var int Index;

//Client
var bool bRegistered;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		RPRI, Index;
}

simulated event Tick(float dt)
{
	if(Role < ROLE_Authority && !bRegistered)
	{
		if(RPRI != None && RPRI.bClientSyncDone && Index >= 0)
		{
			RPRI.Status[Index] = Self;
			bRegistered = true;
			
			ClientInitialize();
		}
	}
}

simulated function ClientInitialize();

simulated function bool IsVisible();
simulated function string GetText();

defaultproperties
{
	Index=-1
	
	NetUpdateFrequency=1.00
	bOnlyRelevantToOwner=True
}
