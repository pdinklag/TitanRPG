/*
    Synchronizer for spawned pickups with an appearance override.
*/
class Sync_SpawnedPickup extends Sync;

var Pickup Target;

var StaticMesh NewStatic;
var float NewDrawScale;

replication {
	reliable if(Role == ROLE_Authority && bNetInitial)
		Target, NewStatic, NewDrawScale;
}

static function Sync_SpawnedPickup Sync(Pickup Pickup, StaticMesh NewStatic, float NewDrawScale) {
    local Sync_SpawnedPickup Sync;
    
    Sync = Pickup.Spawn(class'Sync_SpawnedPickup');
    Sync.Target = Pickup;
    Sync.NewStatic = NewStatic;
    Sync.NewDrawScale = NewDrawScale;
    Sync.ClientFunction();
    
    return Sync;
}

simulated function bool ClientFunction() {
	if(Target == None) {
		return false;
	} else {
        Target.SetDrawType(DT_StaticMesh);
        Target.SetStaticMesh(NewStatic);
        Target.SetDrawScale(NewDrawScale);
        Target.SetDrawScale3D(vect(1, 1, 1));
        Target.Skins[0] = None;
		return true;
	}
}

function bool ShouldDestroy() {
    if(Target == None) {
        return true;
    } else {
        return false;
    }
}

defaultproperties {
    LifeSpan=60
}
