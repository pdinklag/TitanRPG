//Holder for a pawn's old weapon
//Used by DruidsAbilityNoWeaponDrop to keep a pawn's active weapon 
//and ammo after the pawn dies
class DruidsOldWeaponHolder extends Actor;

struct WeaponHolder
{
	var Weapon Weapon;
	var int AmmoAmounts1;
	var int AmmoAmounts2;
};

var array<WeaponHolder> WeaponHolders;
var Weapon SelectedWeapon;

function PostBeginPlay()
{
	SetTimer(5.0, true);

	Super.PostBeginPlay();
}

function Timer()
{
	if (Controller(Owner) == None || WeaponHolders.length == 0)
		Destroy();
}

function Destroyed()
{
	while(WeaponHolders.length > 0)
	{
		if (WeaponHolders[0].Weapon != None)
			WeaponHolders[0].Weapon.Destroy();
		WeaponHolders.Remove(0, 1);
	}

	Super.Destroyed();
}

defaultproperties
{
     bHidden=True
     RemoteRole=ROLE_None
}
