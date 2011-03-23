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

simulated event PostNetReceive()
{
	Super.PostNetReceive();
	
	if(!bRegistered && RPRI != None && Index >= 0)
	{
		RPRI.Status[Index] = Self;
		bRegistered = true;
		
		ClientInitialize();
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
	bNetNotify=True
}
