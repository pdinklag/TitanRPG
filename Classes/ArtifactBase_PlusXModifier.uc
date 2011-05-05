class ArtifactBase_PlusXModifier extends ArtifactBase_WeaponMaker
	abstract;

var config int X;

const MSG_MustBeMaxed = 0x1000;
const MSG_AlreadyHigher = 0x1001;
const MSG_UnableToModify = 0x1002;

var localized string MsgMustBeMaxed, MsgAlreadyHigher, MsgUnableToModify;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_UnableToModify:
			return default.MsgUnableToModify;
			
		case MSG_AlreadyHigher:
			return default.MsgAlreadyHigher;
			
		case MSG_MustBeMaxed:
			return default.MsgMustBeMaxed;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	OldWeapon = RPGWeapon(Instigator.Weapon);
	if(OldWeapon != None)
	{
		if(RPGWeapon(OldWeapon).MinModifier == RPGWeapon(OldWeapon).MaxModifier)
		{
			Msg(MSG_UnableToModify);
			return false;
		}
	
		if(RPGWeapon(OldWeapon).Modifier < RPGWeapon(OldWeapon).MaxModifier)
		{
			Msg(MSG_MustBeMaxed);
			return false;
		}
		else if(RPGWeapon(OldWeapon).Modifier > RPGWeapon(OldWeapon).MaxModifier)
		{
			Msg(MSG_AlreadyHigher);
			return false;
		}
	}
	else
	{
		Msg(MSG_UnableToModify);
		return false;
	}

	return Super.CanActivate();
}

state Activated
{
	function bool DoEffect()
	{
		if(OldWeapon != None)
		{
			RPGWeapon(OldWeapon).SetModifier(RPGWeapon(OldWeapon).MaxModifier + X);

			RPGWeapon(OldWeapon).bCanThrow = false;
			RPGWeapon(OldWeapon).ModifiedWeapon.bCanThrow = false;
			RPGWeapon(OldWeapon).Identify(true);
			return true;
		}
		else
		{
			Msg(MSG_UnableToModify);
			return false;
		}
	}
}

defaultproperties
{
	MsgMustBeMaxed="Your weapon must be at MAX magic in order to modify it."
	MsgAlreadyHigher="Your weapon is already higher than MAX magic."
	MsgUnableToModify="Unable to modify your weapon."
	CostPerSec=150
	MinActivationTime=1.000000
	HudColor=(G=0)
	bCanBeTossed=False
}
