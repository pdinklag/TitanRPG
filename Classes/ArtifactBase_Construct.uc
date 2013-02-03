class ArtifactBase_Construct extends ArtifactBase_Summon
    abstract
    HideDropDown;

var config float ClearRadius;

var array<class<Actor> > BlockingTypes;

var localized string MsgCantConstruct;
var localized array<string> BlockingTypeStrings;

const MSG_CantConstruct = 0x300;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj) {
    if((Msg & MSG_CantConstruct) == MSG_CantConstruct) {
        return Repl(default.MsgCantConstruct, "$1", default.BlockingTypeStrings[Msg & 0xFF]);
    } else {
        return Super.GetMessageString(Msg, Value, Obj);
    }
}

function Actor SpawnActor(class<Actor> SpawnClass, vector SpawnLoc, rotator SpawnRot) {
    local Actor A;
    local int i, Blocker;
    
    Blocker = -1;
    foreach RadiusActors(class'Actor', A, ClearRadius, SpawnLoc) {
        for(i = 0; i < BlockingTypes.Length; i++) {
            if(ClassIsChildOf(A.class, BlockingTypes[i])) {
                Log("Can't construct here because of" @ A);
                Blocker = i;
                break;
            }
        }
    }
    
    if(Blocker >= 0) {
        bShowFailureMessage = false;
        Msg(MSG_CantConstruct | Blocker);
        return None;
    } else {
        bShowFailureMessage = true;
        return Super.SpawnActor(SpawnClass, SpawnLoc, SpawnRot);
    }
}

defaultproperties {
    ClearRadius=256

    MsgCantConstruct="Cannot construct here because of a nearby $1."
    BlockingTypes(0)=class'GameObjective'
    BlockingTypes(1)=class'PlayerStart'
    BlockingTypes(2)=class'SVehicleFactory'
    BlockingTypes(3)=class'Teleporter'
    BlockingTypes(4)=class'JumpPad'
    BlockingTypes(5)=class'LiftCenter'
    BlockingTypes(6)=class'xPickupBase'
    BlockingTypes(7)=class'WeaponLocker'
    BlockingTypes(8)=class'ASTurret'
    BlockingTypes(9)=class'RPGTotem'
    BlockingTypeStrings(0)="game objective"
    BlockingTypeStrings(1)="player start"
    BlockingTypeStrings(2)="vehicle spawn"
    BlockingTypeStrings(3)="teleporter"
    BlockingTypeStrings(4)="jump pad"
    BlockingTypeStrings(5)="lift"
    BlockingTypeStrings(6)="pickup base"
    BlockingTypeStrings(7)="weapon locker"
    BlockingTypeStrings(8)="turret"
    BlockingTypeStrings(9)="totem"
}
