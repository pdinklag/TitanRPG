class Ability_Denial extends RPGAbility;

var config array<class<Weapon> > ForbiddenWeaponTypes;

struct StoredWeapon
{
	var class<Weapon> WeaponClass;
	var class<RPGWeaponModifier> ModifierClass;
	var int Modifier;
	var int Ammo[2];
};
var array<StoredWeapon> StoredWeapons;

/*
	This isn't beautiful, but I can't think of any other way to describe this...
	ExtraSavingLevel determines the level from which on weapons are saved when
	you died in a vehicle or while carrying the ball launcher (in Bombing Run).
	
	In TC06 that's all included in level 2,
	but in TitanRPG it's not featured before level 3.
*/
var config int ExtraSavingLevel;
var config int StoreAllLevel;

simulated function int Cost()
{
    return Super.Cost();
}

static function bool CanSaveWeapon(Weapon W)
{
	local int x;

	if(W == None)
		return false;
		
	for(x = 0; x < default.ForbiddenWeaponTypes.Length; x++)
	{
		if(ClassIsChildof(W.class, default.ForbiddenWeaponTypes[x]))
			return false;
	}

	return true;
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	local Inventory Inv;
	local Weapon W;
	local Ability_VehicleEject EjectorSeat;

	// Ejector Seat hack.
	if(Vehicle(Killed) != None && Killed.Controller != None)
	{
		EjectorSeat = Ability_VehicleEject(RPRI.GetOwnedAbility(class'Ability_VehicleEject'));
		if(EjectorSeat != None && EjectorSeat.CanEjectDriver(Vehicle(Killed)))
			return false;
	}
	
	if(Killed.IsA('Vehicle')) {
        if(AbilityLevel >= ExtraSavingLevel) {
            Killed = Vehicle(Killed).Driver;
        } else {
            return false;
        }
    }

	if(Painter(Killed.Weapon) != None || Redeemer(Killed.Weapon) != None) {
		RPRI.Controller.LastPawnWeapon = None;
	} else if(Killed.Weapon != None) {
		RPRI.Controller.LastPawnWeapon = Killed.Weapon.Class;
	}
	
	if(AbilityLevel > 1) {
		W = None;
		if(AbilityLevel >= StoreAllLevel)
		{
			//store all weapons
			for(Inv = Killed.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				W = Weapon(Inv);
				if(W != None)
					TryStoreWeapon(W);
			}
		}
		else
		{
			//store last held weapon
			if(Killed.IsA('Vehicle'))
			{
				if(AbilityLevel >= ExtraSavingLevel)
					W = Vehicle(Killed).Driver.Weapon;
			}
			else
			{
				W = Killed.Weapon;
			}

			if(AbilityLevel >= ExtraSavingLevel)
			{
				//when carrying the ball launcher, save the old weapon
				if(RPGBallLauncher(W) != None) {
					W = RPGBallLauncher(W).RestoreWeapon;
                }
			}

			if(W != None)
				TryStoreWeapon(W);
		}
	}
	
	//Make current weapon unthrowable so it doesn't get dropped
	if(Killed.Weapon != None)
		Killed.Weapon.bCanThrow = false;
	
	return false;
}

function TryStoreWeapon(Weapon W)
{
	local RPGWeaponModifier WM;
	local StoredWeapon SW;
	
	if(W == None || !CanSaveWeapon(W))
		return;
	
    SW.WeaponClass = W.class;

    SW.Ammo[0] = W.AmmoAmount(0);
    SW.Ammo[1] = W.AmmoAmount(1);
    
	WM = class'RPGWeaponModifier'.static.GetFor(W);
	if(WM != None) {
        SW.ModifierClass = WM.class;
        SW.Modifier = WM.Modifier;
	} else {
		SW.ModifierClass = None;
		SW.Modifier = 0;
	}
	
	StoredWeapons[StoredWeapons.Length] = SW;
}

function ModifyPawn(Pawn Other)
{
	local int i;

	Super.ModifyPawn(Other);
	
    if(AbilityLevel < 2)
        return;

	for(i = 0; i < StoredWeapons.Length; i++)
	{
		RPRI.QueueWeapon(
			StoredWeapons[i].WeaponClass,
			StoredWeapons[i].ModifierClass,
			StoredWeapons[i].Modifier,
			StoredWeapons[i].Ammo[0],
			StoredWeapons[i].Ammo[1]
		);
	}

	StoredWeapons.Length = 0;
}

defaultproperties
{
	AbilityName="Denial"
	LevelDescription(0)="Level 1 of this ability prevents you from dropping your weapon when you die."
	LevelDescription(1)="Level 2 allows you to respawn with the weapon and ammo you were using when you died (unless you died in a vehicle or if you were holding a super weapon or the Ball Launcher)."
	LevelDescription(2)="Level 3 saves your last selected weapon even when you die in a vehicle. If you were holding the Ball Launcher, your previously selected weapon is saved."
	LevelDescription(3)="Level 4 always saves all of your weapons (except for super weapons)."
	MaxLevel=4
	bUseLevelCost=true
	LevelCost(0)=10
	LevelCost(1)=20
	LevelCost(2)=10
	LevelCost(3)=15
	ForbiddenWeaponTypes(0)=class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(2)=class'XWeapons.Painter'
	ForbiddenWeaponTypes(3)=class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(4)=class'UT2k4AssaultFull.Weapon_SpaceFighter'
	ForbiddenWeaponTypes(5)=class'UT2k4AssaultFull.Weapon_SpaceFighter_Skaarj'
	ForbiddenWeaponTypes(6)=class'UT2k4Assault.Weapon_Turret_Minigun' //however this should happen...
	ExtraSavingLevel=3
	StoreAllLevel=4
	Category=class'AbilityCategory_Weapons'
}
