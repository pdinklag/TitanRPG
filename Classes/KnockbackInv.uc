class KnockbackInv extends Inventory;

var Pawn PawnOwner;
var int Modifier;

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	PawnOwner = Other;

	if(PawnOwner == None)
	{
		Destroy();
		return;
	}

	SetTimer(1 / Modifier, true);
	Super.GiveTo(Other);
}

event Tick(float dt)
{
	if(PawnOwner == None)
	{
		Destroy();
		return;
	}

	if(PawnOwner.PlayerReplicationInfo != None &&
		PawnOwner.PlayerReplicationInfo.HasFlag != None)
	{
		PawnOwner.Velocity = vect(0, 0, 0); //Good ol' trick disabled
		Destroy();
	}
}

function Timer()
{
	if(PawnOwner.Physics != PHYS_Hovering && PawnOwner.Physics != PHYS_Falling)
		Destroy();
}

event Destroyed()
{
	if(PawnOwner == None)
		return;

	if(PawnOwner.Physics != PHYS_Walking && PawnOwner.Physics != PHYS_Falling) //still going?
		PawnOwner.setPhysics(PHYS_Falling);

	Super.Destroyed();
}

defaultproperties
{
	bOnlyRelevantToOwner=False
	bAlwaysRelevant=True
	bReplicateInstigator=True
}
