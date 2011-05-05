class AbilityDenial extends RPGAbility;

var config array<class<Weapon> > ForbiddenWeaponTypes;

struct StoredWeapon
{
	var class<Weapon> WeaponClass;
	var class<RPGWeapon> ModifierClass;
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

var bool bTC0X; //for BattleMode's ONSRPG compatibility

simulated function int Cost()
{
    if(RPRI != None && AbilityLevel == (MaxLevel - 1)) //extra requirement for the final level
    {

		if(
			RPRI.HasAbility(class'AbilityLoadedArtifacts') == 0 &&
			(!bTC0X || RPRI.HasAbility(class'AbilityLoadedMedic') == 0) //in ONSRPG, Loaded Medic works too
		)
		{
			return 0;
		}
    }
	
    return Super.Cost();
}

static function bool CanSaveWeapon(Weapon W)
{
	local int x;
	local class<Weapon> WClass;

	if(W == None)
		return false;
		
	if(RPGWeapon(W) != None)
		WClass = RPGWeapon(W).ModifiedWeapon.class;
	else
		WClass = W.class;

	for(x = 0; x < default.ForbiddenWeaponTypes.Length; x++)
	{
		if(ClassIsChildof(WClass, default.ForbiddenWeaponTypes[x]))
			return false;
	}

	return true;
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	local Inventory Inv;
	local Weapon W;
	local AbilityVehicleEject EjectorSeat;

	// Ejector Seat hack.
	if(Vehicle(Killed) != None && Killed.Controller != None)
	{
		EjectorSeat = AbilityVehicleEject(RPRI.GetOwnedAbility(class'AbilityVehicleEject'));
		if(EjectorSeat != None && EjectorSeat.CanEjectDriver(Vehicle(Killed)))
			return false;
	}
	
	if(AbilityLevel >= ExtraSavingLevel && Killed.IsA('Vehicle'))
		Killed = Vehicle(Killed).Driver;

	if(RPGWeapon(Killed.Weapon) != None)
	{
		if(Painter(RPGWeapon(Killed.Weapon).ModifiedWeapon) == None &&
			Redeemer(RPGWeapon(Killed.Weapon).ModifiedWeapon) == None)
			RPRI.Controller.LastPawnWeapon = RPGWeapon(Killed.Weapon).ModifiedWeapon.Class;
		else
			RPRI.Controller.LastPawnWeapon = None;
	}
	else if(Painter(Killed.Weapon) != None || Redeemer(Killed.Weapon) != None)
	{
		RPRI.Controller.LastPawnWeapon = None;
	}
	else if(Killed.Weapon != None)
	{
		RPRI.Controller.LastPawnWeapon = Killed.Weapon.Class;
	}
	
	if(AbilityLevel > 1)
	{
		W = None;
		if(AbilityLevel >= MaxLevel)
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
				if(RPGBallLauncher(W) != None)
					W = RPGBallLauncher(W).RestoreWeapon;
				else if(RPGWeapon(W) != None && RPGBallLauncher(RPGWeapon(W).ModifiedWeapon) != None)
					W = RPGBallLauncher(RPGWeapon(W).ModifiedWeapon).RestoreWeapon;
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
	local RPGWeapon RW;
	local StoredWeapon SW;
	
	if(W == None || !CanSaveWeapon(W))
		return;
	
	RW = RPGWeapon(W);
	if(RW != None)
	{
		SW.WeaponClass = RW.ModifiedWeapon.class;
		SW.ModifierClass = RW.class;
		SW.Modifier = RW.Modifier;
		SW.Ammo[0] = RW.AmmoAmount(0);
		SW.Ammo[1] = RW.AmmoAmount(1);
	}
	else
	{
		SW.WeaponClass = W.class;
		SW.ModifierClass = None;
		SW.Modifier = 0;
		SW.Ammo[0] = W.AmmoAmount(0);
		SW.Ammo[1] = W.AmmoAmount(1);
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
	bTC0X=False
	AbilityName="Denial"
	LevelDescription(0)="Level 1 of this ability prevents you from dropping your weapon when you die."
	LevelDescription(1)="Level 2 allows you to respawn with the weapon and ammo you were using when you died (unless you died in a vehicle or if you were holding a super weapon or the Ball Launcher)."
	LevelDescription(2)="Level 3 saves your last selected weapon even when you die in a vehicle. If you were holding the Ball Launcher, your previously selected weapon is saved."
	LevelDescription(3)="If you have Loaded Artifacts, you may buy Level 4 which always saves all of your weapons (save for super weapons)."
	MaxLevel=4
	bUseLevelCost=true
	LevelCost(0)=10
	LevelCost(1)=20
	LevelCost(2)=10
	LevelCost(3)=15
	RequiredLevels(0)=25
	ForbiddenWeaponTypes(0)=class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(2)=class'XWeapons.Painter'
	ForbiddenWeaponTypes(3)=class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(4)=class'UT2k4AssaultFull.Weapon_SpaceFighter'
	ForbiddenWeaponTypes(5)=class'UT2k4AssaultFull.Weapon_SpaceFighter_Skaarj'
	ForbiddenWeaponTypes(6)=class'UT2k4Assault.Weapon_Turret_Minigun' //however this should happen...
	ExtraSavingLevel=3
	Category=class'AbilityCategory_Weapons'
}
