/*
	I'm sick of adding functions to the RPGPlayerReplicationInfo for things like
	projectile speeds (Force).
	
	This is a new solution attempt, an Actor that will be spawned on all clients,
	just to transmit certain information to them.
	
	ClientFunction is to do whatever is supposed to do on the client, all information
	required can simply be replicated.
*/
class Sync extends Actor;

var bool bTryEachTick; //attempt to execute the client function each tick

simulated event Tick(float dt) {
    Super.Tick(dt);
    
    if(Role == ROLE_Authority) {
        if(ShouldDestroy()) {
            Destroy();
        }
    } else if(Role < ROLE_Authority && bTryEachTick) {
        if(ClientFunction()) {
            Destroy();
        }
    }
}

simulated event PostNetReceive() {
    Super.PostNetReceive();
    
    if(Role < ROLE_Authority) {
        if(ClientFunction()) {
            Destroy();
        }
    }
}

//return true if this should be destroyed (client)
simulated function bool ClientFunction();

//return true if this should be destroyed (server)
function bool ShouldDestroy();

defaultproperties {
    LifeSpan=10.00
    DrawType=DT_None
    bNetTemporary=True
    bNetNotify=True
    bTryEachTick=False
    bReplicateInstigator=True
    bReplicateMovement=False
    bOnlyRelevantToOwner=False
    bAlwaysRelevant=True
    bSkipActorPropertyReplication=True
    RemoteRole=ROLE_SimulatedProxy
}
