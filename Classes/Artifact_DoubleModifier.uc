class Artifact_DoubleModifier extends RPGArtifact;

var RPGWeapon Weapon;
var bool oldCanThrow;

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
	local RPGWeapon OldWeapon;

	OldWeapon = RPGWeapon(Instigator.Weapon);
	if(OldWeapon == None || OldWeapon.MinModifier == OldWeapon.MaxModifier)
	{
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

		Weapon = RPGWeapon(Instigator.Weapon);
		if(Weapon == None)
		{
			GotoState('');
		}
		else
		{
			Weapon.SetModifier(Weapon.Modifier * 2);

			oldCanThrow = Weapon.bCanThrow;
			Weapon.bCanThrow = false;
			Weapon.ModifiedWeapon.bCanThrow = false;
			//class'IdentifierInv'.static.Identify(Weapon);
			Weapon.Identify(true);
		}
	}

	event Tick(float dt)
	{
		Super.Tick(dt);
	
		if(Instigator.Weapon != Weapon)
			GotoState('');
	}

	function EndState()
	{
		if(Weapon != None)
		{
			Weapon.SetModifier(Weapon.Modifier / 2);
			
			/*
				EXPLOIT FIX: If the Instigator entered a vehicle, SetModifier will reactivate the weapon modifier, stacking the modifier
				for the Instigator. Therefore, stop the effect immediately.
			*/
			if(Instigator.DrivenVehicle != None)
				Weapon.StopEffect();
			
			Weapon.bCanThrow = oldCanThrow;
			Weapon.ModifiedWeapon.bCanThrow = oldCanThrow;
			//class'IdentifierInv'.static.Identify(Weapon);
			Weapon.Identify(true);
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
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.DoubleMod'
	ItemName="Double Magic Modifier"
}
