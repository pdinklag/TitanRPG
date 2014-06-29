class RPGTotemController extends AIController;

var Controller Master;
var RPGPlayerReplicationInfo MasterRPRI;

var FriendlyPawnReplicationInfo FPRI;

event PostBeginPlay() {
    Super.PostBeginPlay();
    FPRI = Spawn(class'FriendlyPawnReplicationInfo');
}

function SetMaster(Controller NewMaster) {
    Master = NewMaster;
    MasterRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Master);
    FPRI.Master = Master.PlayerReplicationInfo;
    
    if(RPGTotem(Pawn) != None) {
        RPGTotem(Pawn).SetMaster(NewMaster);
    }
}

function Possess(Pawn aPawn) {
	super.Possess(aPawn);
    FPRI.Pawn = aPawn;
}

function int GetTeamNum() {
	if(Vehicle(Pawn) != None)
		return Vehicle(Pawn).Team;

	return super.GetTeamNum();
}

event Tick(float dt) {
    Super.Tick(dt);
    
    if(Pawn == None || Pawn.Controller != Self || Pawn.bPendingDelete) {
        Destroy();
        return;
    }

	//if I don't have a master or he switched teams, I should die
    if(
        Master == None ||
        Master.PlayerReplicationInfo == None ||
        Master.PlayerReplicationInfo.bOnlySpectator ||
        !SameTeamAs(Master)
    ) {
        Pawn.Suicide();
    } else if(MasterRPRI != None) {
        //if my master died, test if I should as well
        if(MasterRPRI.bTotemsDie && (Master.Pawn == None || Master.Pawn.Health <= 0)) {
            Pawn.Suicide();
        }
    }
}

defaultproperties {
}
