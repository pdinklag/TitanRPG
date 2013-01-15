class ArtifactBase_PlusXModifier extends ArtifactBase_WeaponMaker
	abstract
    HideDropDown;

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
    local RPGWeaponModifier WM;
    
	if(Instigator.Weapon != None) {
        WM = class'RPGWeaponModifier'.static.GetFor(Instigator.Weapon);
        if(WM == None || WM.MinModifier == WM.MaxModifier) {
            Msg(MSG_UnableToModify);
            return false;
        }
    
        if(WM.Modifier < WM.MaxModifier) {
            Msg(MSG_MustBeMaxed);
            return false;
        } else if(WM.Modifier > WM.MaxModifier) {
            Msg(MSG_AlreadyHigher);
            return false;
        }
	}
	else {
		Msg(MSG_UnableToModify);
		return false;
	}

	return Super.CanActivate();
}

state Activated
{
	function bool DoEffect()
	{
        local RPGWeaponModifier WM;
    
		if(OldWeapon != None) {
            WM = class'RPGWeaponModifier'.static.GetFor(Instigator.Weapon);
            if(WM != None) {
                WM.SetModifier(WM.MaxModifier + X, true);
                return true;
            } else {
                Msg(MSG_UnableToModify);
                return false;
            }
		}
		else {
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
