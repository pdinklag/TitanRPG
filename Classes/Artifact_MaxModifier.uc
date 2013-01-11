class Artifact_MaxModifier extends ArtifactBase_WeaponMaker hidedropdown;

const MSG_UnableToModify = 0x1000;
const MSG_AlreadyMaxed = 0x1001;

var localized string MsgUnableToModify, MsgAlreadyMaxed;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_UnableToModify:
			return default.MsgUnableToModify;
			
		case MSG_AlreadyMaxed:
			return default.MsgAlreadyMaxed;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
    local RPGWeaponModifier WM;

	if(Instigator != None && Instigator.Weapon != None)
	{
        WM = class'RPGWeaponModifier'.static.GetFor(Instigator.Weapon);
        if(WM != None) {
			if(WM.MinModifier == WM.MaxModifier) {
				Msg(MSG_UnableToModify);
				return false;
			}
		
			if(WM.Modifier >= WM.MaxModifier) {
				Msg(MSG_AlreadyMaxed);
				return false;
			}
		} else {
			Msg(MSG_UnableToModify);
			return false;
		}
	}
	
	return Super.CanActivate();
}

state Activated
{
	function bool DoEffect()
	{
        local RPGWeaponModifier WM;

		if(OldWeapon == None) {
			Msg(MSG_UnableToModify);
			return false;
		}
        
        WM = class'RPGWeaponModifier'.static.GetFor(OldWeapon);
		if(WM == None) {
			Msg(MSG_UnableToModify);
			return false;
		}
        
        WM.SetModifier(WM.MaxModifier, true);
		return true;
	}
}

defaultproperties
{
	MsgAlreadyMaxed="Your weapon is already at or higher than MAX magic."
	MsgUnableToModify="Unable to max your weapon."
	MinActivationTime=1.000000
	CostPerSec=100
	HudColor=(B=224,G=192)
	ArtifactID="Max"
	bCanBeTossed=False
	Description="Maximizes the magic level of your weapon."
	IconMaterial=Texture'TitanRPG.ArtifactIcons.MaxMod'
	ItemName="Max Magic Modifier"
}
