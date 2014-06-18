/*
    Synchronizer for switched scorpion turrets.
*/
class Sync_ScorpionTurret extends Sync;

var ONSRV Scorp;
var ONSWeapon NewWeapon;

replication {
	reliable if(Role == ROLE_Authority && bNetInitial)
		Scorp, NewWeapon;
}

static function Sync_ScorpionTurret Sync(ONSRV Scorp, ONSWeapon NewWeapon) {
    local Sync_ScorpionTurret Sync;
    
    Sync = Scorp.Spawn(class'Sync_ScorpionTurret');
    Sync.Scorp = Scorp;
    Sync.NewWeapon = NewWeapon;
    
    return Sync;
}

simulated function bool ClientFunction() {
    Log("Sync_ScorpionTurret.ClientFunction: Scorp =" @ Scorp $ ", NewWeapon =" @ NewWeapon);
	if(Scorp == None || NewWeapon == None) {
		return false;
	} else {
        Scorp.TeamChanged(); //force a skin re-load
		return true;
	}
}

function bool ShouldDestroy() {
    if(Scorp == None) {
        return true;
    } else {
        return false;
    }
}

defaultproperties {
    Lifetime=3
}
