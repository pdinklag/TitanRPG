class ArtifactBase_WeaponMaker extends ArtifactBase_DelayedUse
	abstract;

var config bool bAvoidRepetition;

var config array<class<Weapon> > ForbiddenWeaponTypes;

const MSG_UnableToGenerate = 0x0100;
const MSG_AlreadyConstructing = 0x0101;
const MSG_Broken = 0x0102;

var localized string MsgUnableToGenerate, MsgAlreadyConstructing, MsgBroken;

var Weapon OldWeapon;
var() Sound BrokenSound;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_UnableToGenerate:
			return default.MsgUnableToGenerate;
			
		case MSG_AlreadyConstructing:
			return default.MsgAlreadyConstructing;
			
		case MSG_Broken:
			return default.MsgBroken;
	
		default:
			return Super.GetMessageString(Msg, Value);
	}
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if(Role < ROLE_Authority)
		return;
}

function bool CanActivate()
{
	local int i;
	local class<Weapon> OldWeaponClass;
	
	if(!Super.CanActivate())
		return false;

	OldWeapon = Instigator.Weapon;
	
	if(RPGWeapon(OldWeapon) != None)
		OldWeaponClass = RPGWeapon(OldWeapon).ModifiedWeapon.class;
	else if(OldWeapon != None)
		OldWeaponClass = OldWeapon.class;

	if(OldWeapon != None)
	{
		for(i = 0; i < ForbiddenWeaponTypes.Length; i++)
		{
			if(ClassIsChildOf(OldWeaponClass, ForbiddenWeaponTypes[i]))
			{
				OldWeapon = None;
				break;
			}
		}
	}

	if(OldWeapon == None)
	{
		Msg(MSG_UnableToGenerate);
		return false;
	}
	
	return true;
}


state Activated
{
	function bool DoEffect()
	{
		//local Ability_LoadedArtifacts LA;
		local Inventory Copy;
		local class<RPGWeapon> NewWeaponClass;
		local class<Weapon> OldWeaponClass;
		local int x, tries;

		if(OldWeapon == None)
		{
			Msg(MSG_UnableToGenerate);
			return false;
		}

		//in this case, use the new weapon class anyway.
		if(OldWeapon.isA('RPGWeapon'))
			OldWeaponClass = RPGWeapon(OldWeapon).ModifiedWeapon.class;
		else
			OldWeaponClass = OldWeapon.class;

		if(OldWeaponClass == None)
		{
			Msg(MSG_UnableToGenerate);
			return false;
		}

		for(x = 0; x < 50; x++)
		{
			if(bAvoidRepetition)
			{
				//try to generate a weapon of different magic than the old one
				for(tries = 0; tries < 50; tries++)
				{
					NewWeaponClass = GetRandomWeaponModifier(OldWeaponClass, Instigator);
					
					if(NewWeaponClass != OldWeapon.class)
						tries = 50; //break inner loop
				}
			}
			else
				NewWeaponClass = GetRandomWeaponModifier(OldWeaponClass, Instigator);
				
			if(NewWeaponClass.static.AllowedFor(OldWeaponClass, Instigator))
				break;
		}
		
		if(x == 50 || NewWeaponClass == None)
		{
			Msg(MSG_UnableToGenerate);
			return false;
		}

		Copy = spawn(NewWeaponClass, Instigator,,, rot(0,0,0));
		if(Copy == None)
		{
			Msg(MSG_UnableToGenerate);
			return false;
		}

		if(InstigatorRPRI != None)
		{
			for (x = 0; x < InstigatorRPRI.OldRPGWeapons.length; x++)
			{
				if(oldWeapon == InstigatorRPRI.OldRPGWeapons[x].Weapon)
				{
					InstigatorRPRI.OldRPGWeapons.Remove(x, 1);
					break;
				}
			}
		}

		if(RPGWeapon(Copy) == None)
		{
			Msg(MSG_UnableToGenerate);
			return false;
		}

		//try to generate a positive weapon.
		for(x = 0; x < 50; x++)
		{
			RPGWeapon(Copy).Generate(None);
			if(RPGWeapon(Copy).Modifier > -1)
				break;
		}

		RPGWeapon(Copy).SetModifiedWeapon(spawn(OldWeaponClass, Instigator,,, rot(0,0,0)), true);
		//stupid hack for speedy weapons since I can't seem to get them to work with DetachFromPawn correctly. :P
		//if(OldWeapon.isA('WeaponQuickfoot')) //FIXME
		//	(WeaponQuickfoot(OldWeapon)).deactivate();
		
		OldWeapon.DetachFromPawn(Instigator);
		if(RPGWeapon(OldWeapon) != None)
		{
			RPGWeapon(OldWeapon).ModifiedWeapon.Destroy();
			RPGWeapon(OldWeapon).ModifiedWeapon = None;
		}
		OldWeapon.Destroy();
		Copy.GiveTo(Instigator);

        //Former breaking logic
        /*
		LA = Ability_LoadedArtifacts(InstigatorRPRI.GetOwnedAbility(class'Ability_LoadedArtifacts'));
		if(LA == None || !LA.ProtectArtifacts())
		{
			if(bCanBreak && Rand(3) == 0) //25% chance
			{
				Msg(MSG_Broken);
				
				if(PlayerController(Instigator.Controller) != None)
			        PlayerController(Instigator.Controller).ClientPlaySound(BrokenSound);
				
				Destroy();
			}
		}
        */
		
		return true;
	}
}

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other);

defaultproperties
{
	bAllowInVehicle=False
	MsgUnableToGenerate="Unable to enchant weapon."
	MsgAlreadyConstructing="Already enchanting a weapon."
	MsgBroken="The artifact has broken."
	ForbiddenWeaponTypes(0)=class'BallLauncher'
	ForbiddenWeaponTypes(1)=class'TransLauncher'
}
