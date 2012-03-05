class Artifact_Decoy extends RPGArtifact;

const MSG_OnlyInVehicle = 0x1000;
const MSG_OnlyOneAtATime = 0x1001;

var localized string OnlyInVehicleText, OnlyOneAtATimeText;

var RPGDecoy Decoy;

function BotIncomingMissile(Bot Bot, Projectile P)
{
	if(P.IsA('RPGONSAVRiLRocket'))
		Activate();
}

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_OnlyInVehicle:
			return default.OnlyInVehicleText;
		
		case MSG_OnlyOneAtATime:
			return default.OnlyOneAtATimeText;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	if(Decoy != None)
	{
		Msg(MSG_OnlyOneAtATime);
		return false;
	}

	if(Vehicle(Instigator) == None)
	{
		Msg(MSG_OnlyInVehicle);
		return false;
	}
	
	return Super.CanActivate();
}

function bool DoEffect()	
{
	local rotator Dir;

	if(Instigator.IsA('ONSAttackCraft'))
		Dir = Instigator.Rotation;
	else
		Dir = rotator(vector(Instigator.Rotation) + vect(0, 0, 1));

	Decoy = Instigator.Spawn(
		class'RPGDecoy',
		Instigator, , 
		Instigator.Location + Instigator.CollisionRadius * vector(Dir),
		Dir
	);
	
	return (Decoy != None);
}

defaultproperties
{
	Cooldown=10
	OnlyInVehicleText="The Decoy can only be used in a vehicle."
	OnlyOneAtATimeText="You can only fire one decoy at a time."
	ArtifactID="Decoy"
	bCanBeTossed=False
	Description="Distracts incoming homing missiles."
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Decoy'
	ItemName="Decoy"
	PickupClass=Class'ArtifactPickup_Decoy'
}
