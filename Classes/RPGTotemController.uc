class RPGTotemController extends AIController;

var Controller Master;

function Possess(Pawn aPawn) {
	super.Possess(aPawn);
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
