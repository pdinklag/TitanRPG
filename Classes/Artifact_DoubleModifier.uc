class Artifact_DoubleModifier extends RPGArtifact hidedropdown;

var RPGWeaponModifier WeaponModifier;
var bool OldCanThrow;

const MSG_UnableToModify = 0x1000;

var localized string MsgUnableToModify;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_UnableToModify:
			return default.MsgUnableToModify;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	local RPGWeaponModifier WM;

	if(Instigator.Weapon == None) {
		Msg(MSG_UnableToModify);
		return false;
	}
    
    WM = class'RPGWeaponModifier'.static.GetFor(Instigator.Weapon);
    if(WM == None || WM.MinModifier == WM.MaxModifier) {
		Msg(MSG_UnableToModify);
		return false;
    }
    
	return Super.CanActivate();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();

        WeaponModifier = class'RPGWeaponModifier'.static.GetFor(Instigator.Weapon);
		if(WeaponModifier == None) {
			GotoState('');
		} else {
            OldCanThrow = Instigator.Weapon.bCanThrow;
			WeaponModifier.SetModifier(WeaponModifier.Modifier * 2, true);
			Instigator.Weapon.bCanThrow = false;
		}
	}

	event Tick(float dt)
	{
		Super.Tick(dt);
	
		if(Instigator.Weapon != WeaponModifier.Weapon)
			GotoState('');
	}

	function EndState()
	{
		if(WeaponModifier != None) {
			WeaponModifier.SetModifier(WeaponModifier.Modifier / 2, true);
			WeaponModifier.Weapon.bCanThrow = OldCanThrow;
		}

		Super.EndState();
	}
}

defaultproperties
{
	MsgUnableToModify="Unable to modify your weapon."
	bAllowInVehicle=False
	CostPerSec=8
	MinActivationTime=1.000000
	HudColor=(G=128)
	ArtifactID="Double"
	bCanBeTossed=False
	bExclusive=True
	Description="Doubles your weapon's magic level."
	IconMaterial=Texture'TitanRPG.ArtifactIcons.DoubleMod'
	ItemName="Double Magic Modifier"
}
