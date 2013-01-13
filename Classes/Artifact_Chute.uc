class Artifact_Chute extends RPGArtifact hidedropdown;

var config float AirControl, AccelRate;
var config float VelocityZ;
var config float VelocityDamping;

var float OldAccelRate;
var float OldAirControl;

var Sound OpenSound;

const MSG_OnlyIfFalling = 0x1000;

var localized string MsgOnlyIfFalling;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_OnlyIfFalling:
			return default.MsgOnlyIfFalling;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	if(!Super.CanActivate())
		return false;
	
	if(Instigator.Physics == PHYS_Falling &&
		Instigator.Base == None &&
		Instigator.Velocity.Z <= -Instigator.MaxFallSpeed * 0.5f)
	{
		return true;
	}
	else
	{
		Msg(MSG_OnlyIfFalling);
		return false;
	}
}

function bool CanDeactivate()
{
	//return (Instigator.Physics != PHYS_Falling || Instigator.Base != None);
	return Super.CanDeactivate();
}

function BotWhatNext(Bot Bot) {
    //if it can be activated, it's probably required!
    Activate();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();

		Instigator.Acceleration = vect(0, 0, 0);
		
		OldAccelRate = Instigator.AccelRate;
		OldAirControl = Instigator.AirControl;
		
		Instigator.AccelRate = AccelRate;
		Instigator.AirControl = AirControl;
		
		Instigator.Velocity.Z = VelocityZ;
		Instigator.Velocity.X *= VelocityDamping;
		Instigator.Velocity.Y *= VelocityDamping;
		
		Instigator.PlaySound(OpenSound, SLOT_Misc, 512, true, 128);
		
		if(ThirdPersonActor == None)
		{
			ThirdPersonActor = Spawn(AttachmentClass, Owner);
			InventoryAttachment(ThirdPersonActor).InitFor(self);
		}
		else
		{
			ThirdPersonActor.NetUpdateTime = Level.TimeSeconds - 1;
		}
		
		Instigator.AttachToBone(ThirdPersonActor, 'spine');
	}
	
	event Tick(float dt)
	{
		Super.Tick(dt);
		
		if(Instigator != None && Instigator.Physics == PHYS_Falling && Instigator.Base == None)
			Instigator.Velocity.Z = VelocityZ;
		else
			GoToState('');
	}
	
	function EndState()
	{
		Instigator.AccelRate = OldAccelRate;
		Instigator.AirControl = OldAirControl;
		
		DetachFromPawn(Instigator);
	
		Super.EndState();
	}
}

defaultproperties
{
	bAllowInVehicle=False

	AccelRate=512.000000
	AirControl=0.05
	VelocityZ=-400.000000
	VelocityDamping=0.500000

	AttachmentClass=class'ChuteAttachment'
	
	OpenSound=Sound'TitanRPG.Chute.chuteopen'
	
	MinActivationTime=1.000000
	CostPerSec=0
	HudColor=(R=192,G=128,B=64)
	ArtifactID="Chute"
	Description="Opens up a parachute, softening your landing."
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Chute'
	ItemName="Parachute"
	
	MsgOnlyIfFalling="You can only open the parachute if you are falling."
}
