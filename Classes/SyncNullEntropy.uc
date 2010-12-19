/*
	Often when somebody gets nulled, clients do not receive the information properly
	and the target still looks like it's moving, while in fact it is immobile.
	
	This Sync class takes care of that issue.
*/
class SyncNullEntropy extends Sync;

var Pawn Target;
var vector NullLocation;

replication
{
	reliable if(Role == ROLE_Authority)
		Target, NullLocation;
}

simulated function bool ClientFunction()
{
	Target.SetLocation(NullLocation);
	Target.Velocity = vect(0, 0, 0);
	Target.SetPhysics(PHYS_None);

	return true;
}

defaultproperties
{
}
