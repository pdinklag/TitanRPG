class RPGTotemController extends AIController;

var Controller Master;

var FriendlyPawnReplicationInfo FPRI;

event PostBeginPlay() {
    Super.PostBeginPlay();
    FPRI = Spawn(class'FriendlyPawnReplicationInfo');
}

function SetMaster(Controller NewMaster) {
    Master = NewMaster;
    FPRI.Master = Master.PlayerReplicationInfo;
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

    if(Master != None && (Master.Pawn == None || Master.Pawn.Health <= 0)) {
        Pawn.Suicide();
    }
}

defaultproperties {
}
