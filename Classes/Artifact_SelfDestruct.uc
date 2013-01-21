class Artifact_SelfDestruct extends RPGArtifact;

var config int CountdownTime;

var config float DamageRadius;
var config int Damage;
var config float MomentumTransfer;

const MSG_OnlyInVehicle = 0x1000;
const MSG_AlreadyActive = 0x1001;
const MSG_TeamMembers = 0x1002;

var localized string OnlyInVehicleText, AlreadyActiveText, TeamMembersText;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_OnlyInVehicle:
			return default.OnlyInVehicleText;
			
		case MSG_AlreadyActive:
			return default.AlreadyActiveText;
			
		case MSG_TeamMembers:
			return default.TeamMembersText;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function BotFightEnemy(Bot Bot)
{
	if(
		Vehicle(Instigator).Health < 100 &&
		FRand() < 0.75)
	{
		Activate();
	}
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Disable('Tick');
}

function bool CanActivate()
{
	if(ONSVehicle(Instigator) == None && ASVehicle(Instigator) == None)
	{
		Msg(MSG_OnlyInVehicle);
		return false;
	}
	
	if(Instigator.FindInventoryType(class'SelfDestructInv') != None)
	{
		Msg(MSG_AlreadyActive);
		return false;
	}
	
	if(Vehicle(Instigator).NumPassengers() > 1)
	{
		Msg(MSG_TeamMembers);
		return false;
	}
	
	return Super.CanActivate();
}

function bool DoEffect()
{
	local SelfDestructInv SDI;

	SDI = Spawn(class'SelfDestructInv');
	if(SDI != None)
	{
		SDI.V = Vehicle(Instigator);
		SDI.Boesetaeter = Instigator.Controller;
		SDI.CountdownTime = CountdownTime;
		SDI.DamageRadius = DamageRadius;
		SDI.Damage = Damage;
		SDI.MomentumTransfer = MomentumTransfer;
		SDI.GiveTo(Instigator);
	}
	
	return (SDI != None);
}

defaultproperties
{
	OnlyInVehicleText="The Self Destruction can only be used in a vehicle's driver seat."
	AlreadyActiveText="Self destruction has already been initiated."
	TeamMembersText="You cannot destruct the vehicle while other team members are in it."
	ArtifactID="SelfDestruct"
	bCanBeTossed=False
	IconMaterial=Texture'TitanRPG.ArtifactIcons.selfdestruct'
	ItemName="Self Destruction"
	PickupClass=class'ArtifactPickup_SelfDestruct'

	bChargeUp=True
	CountdownTime=3
	Damage=1000
	DamageRadius=1024
	MomentumTransfer=50000
	
	MaxUses=1
}
