class ComboDrone extends Combo;

simulated event Tick(float DeltaTime)
{
	local Pawn P;

	P = Pawn(Owner);
	if(P != None)
	{
		if(class'Drone'.static.SpawnFor(P) != None)
			P.Controller.Adrenaline -= 100;
		else if(PlayerController(P.Controller) != None)
			PlayerController(P.Controller).ReceiveLocalizedMessage(class'ComboDroneMessage', 0);
	}
	
	Destroy();
}

defaultproperties
{
	ExecMessage="Drone!"
	Duration=0.00
	keys(0)=4
	keys(1)=4
	keys(2)=8
	keys(3)=8
}
