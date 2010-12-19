//This holds and maintains the list of the local player's enemy pawns for use in AwarenessInteraction
//A seperate actor is used to prevent invalid pointer problems since Actor references
//in non-Actors don't get set to None automatically when the Actor is destroyed
class AwarenessEnemyList extends Actor;

var array<Pawn> Enemies;
var PlayerController PlayerOwner;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	PlayerOwner = Level.GetLocalPlayerController();
	if (PlayerOwner != None)
		SetTimer(2, true);
	else
		Warn("AwarenessEnemyList spawned with no local PlayerController!");
}

simulated function Timer()
{
	local Pawn P, PlayerDriver;

	Enemies.length = 0;

	if (PlayerOwner.Pawn == None || PlayerOwner.Pawn.Health <= 0)
		return;

	if (Vehicle(PlayerOwner.Pawn) != None)
		PlayerDriver = Vehicle(PlayerOwner.Pawn).Driver;

	foreach DynamicActors(class'Pawn', P)
		if ( P != PlayerOwner.Pawn && P != PlayerDriver
		     && (P.IsA('Monster') || P.GetTeamNum() == 255 || P.GetTeamNum() != PlayerOwner.GetTeamNum())
		     && (Vehicle(P) == None || (Vehicle(P).bDriving && P.GetVehicleBase() == None)) )
			Enemies[Enemies.length] = P;
}

defaultproperties
{
     bHidden=True
     RemoteRole=ROLE_None
     bGameRelevant=True
     bBlockZeroExtentTraces=False
     bBlockNonZeroExtentTraces=False
}
