class Sync_ONSWeaponRotSpeed extends Sync;

var ONSWeapon Target;
var float RotationsPerSecond;

replication {
    reliable if(Role == ROLE_Authority && bNetInitial)
        Target, RotationsPerSecond;
}

simulated function bool ClientFunction() {
    if(Target != None) {
        Target.RotationsPerSecond = RotationsPerSecond;
    } else {
        return true;
    }
}

defaultproperties {
    LifeSpan=4.00
}
