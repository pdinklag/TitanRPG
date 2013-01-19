class RPGTotemController extends AIController;

var Controller Master;

function Possess(Pawn aPawn) {
	super.Possess(aPawn);
}

simulated function int GetTeamNum() {
	if(Vehicle(Pawn) != None)
		return Vehicle(Pawn).Team;

	return super.GetTeamNum();
}

defaultproperties {
}
