class ArtifactBase_WeaponMaker extends ArtifactBase_DelayedUse
	abstract
    HideDropDown;

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
        local RPGWeaponModifier WM;
		local class<RPGWeaponModifier> OldModifier, NewModifier;
		local int x, tries;

		if(OldWeapon == None) {
			Msg(MSG_UnableToGenerate);
			return false;
		}

        WM = class'RPGWeaponModifier'.static.GetFor(OldWeapon);
        if(WM != None) {
            OldModifier = WM.class;
        }

		for(x = 0; x < 50; x++) {
			if(bAvoidRepetition) {
				//try to generate a weapon of different magic than the old one
				for(tries = 0; tries < 50; tries++) {
					NewModifier = GetRandomWeaponModifier(OldWeapon.class, Instigator);
					
					if(NewModifier == None || NewModifier != OldModifier) {
						tries = 50; //break inner loop
                    }
				}
			} else {
				NewModifier = GetRandomWeaponModifier(OldWeapon.class, Instigator);
            }
            
			if(NewModifier == None || NewModifier.static.AllowedFor(OldWeapon.class, Instigator)) {
				break;
            }
		}
		
		if(x == 50) {
			Msg(MSG_UnableToGenerate);
			return false;
		}

        if(NewModifier != None) {
            WM = NewModifier.static.Modify(OldWeapon, NewModifier.static.GetRandomPositiveModifierLevel(), true);
        } else {
            class'RPGWeaponModifier'.static.RemoveModifier(OldWeapon);
        }

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

function class<RPGWeaponModifier> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other);

defaultproperties
{
	bAllowInVehicle=False
	MsgUnableToGenerate="Unable to enchant weapon."
	MsgAlreadyConstructing="Already enchanting a weapon."
	MsgBroken="The artifact has broken."
	ForbiddenWeaponTypes(0)=class'BallLauncher'
	ForbiddenWeaponTypes(1)=class'TransLauncher'
}
