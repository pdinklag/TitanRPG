class Artifact_MaxModifier extends ArtifactBase_WeaponMaker;

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
	if(Instigator != None)
	{
		OldWeapon = RPGWeapon(Instigator.Weapon);
		if(OldWeapon != None)
		{
			if(RPGWeapon(OldWeapon).MinModifier == RPGWeapon(OldWeapon).MaxModifier)
			{
				Msg(MSG_UnableToModify);
				return false;
			}
		
			if(RPGWeapon(OldWeapon).Modifier >= RPGWeapon(OldWeapon).MaxModifier)
			{
				Msg(MSG_AlreadyMaxed);
				return false;
			}
		}
		else
		{
			Msg(MSG_UnableToModify);
			return false;
		}
	}
	
	return Super.CanActivate();
}

state Activated
{
	function DoEffect()
	{
		local inventory Copy;
		local class<RPGWeapon> NewWeaponClass;
		local class<Weapon> OldWeaponClass;
		local int x;
		local RPGPlayerReplicationInfo RPRI;

		if(OldWeapon == None)
		{
			Msg(MSG_UnableToModify);
			return;
		}

		if(RPGWeapon(OldWeapon) != None)
			OldWeaponClass = RPGWeapon(OldWeapon).ModifiedWeapon.class;

		if(OldWeaponClass == None)
		{
			Msg(MSG_UnableToModify);
			return;
		}

		NewWeaponClass = class<RPGWeapon>(OldWeapon.class);
		if(NewWeaponClass == None)
		{
			Msg(MSG_UnableToModify);
			return;
		}

		Copy = spawn(NewWeaponClass, Instigator,,, rot(0,0,0));

		if(Copy == None)
		{
			Msg(MSG_UnableToModify);
			return;
		}

		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if (RPRI != None && RPGWeapon(oldWeapon) != None)
		{
			for (x = 0; x < RPRI.OldRPGWeapons.length; x++)
			{
				if(RPGWeapon(oldWeapon).ModifiedWeapon == RPRI.OldRPGWeapons[x].Weapon)
				{
					RPRI.OldRPGWeapons.Remove(x, 1);
					break;
				}
			}
		}

		if(RPGWeapon(Copy) == None)
		{
			Msg(MSG_UnableToModify);
			return;
		}

		RPGWeapon(Copy).Generate(None);
		RPGWeapon(Copy).Modifier = RPGWeapon(Copy).MaxModifier;
		RPGWeapon(Copy).SetModifiedWeapon(spawn(OldWeaponClass, Instigator,,, rot(0,0,0)), true);

		//stupid hack for speedy weapons since I can't seem to get them to work with DetachFromPawn correctly. :P
		//if(WeaponQuickfoot(OldWeapon) != None) //FIXME
		//	(WeaponQuickfoot(OldWeapon)).deactivate();

		OldWeapon.DetachFromPawn(Instigator);
		if(RPGWeapon(OldWeapon) != None)
		{
			RPGWeapon(OldWeapon).ModifiedWeapon.Destroy();
			RPGWeapon(OldWeapon).ModifiedWeapon = None;
		}

		OldWeapon.Destroy();
		Copy.GiveTo(Instigator);
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
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.MaxMod'
	ItemName="Max Magic Modifier"
}
