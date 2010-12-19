class AbilityDenial extends RPGAbility
	DependsOn(DruidsOldWeaponHolder);

var config array<class<Weapon> > ForbiddenWeaponTypes;

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
	
	if(RPRI.OldWeaponHolder != None)
		RPRI.OldWeaponHolder.Destroy();

	if(Killed != None && !Killed.IsA('Vehicle'))
		StoreOldWeapons(Killed, RPRI, AbilityLevel >= ExtraSavingLevel, AbilityLevel >= MaxLevel);

	Killed.Weapon = None;
	return false;
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
    if(AbilityLevel < 2)
        return;

	RestoreOldWeapons(Other, RPRI);
}

//Static for other uses
static function StoreOldWeapons(Pawn Killed, RPGPlayerReplicationInfo RPRI, bool bStoreExtra, bool bStoreAll)
{
	local array<Weapon> Weapons;
	local Weapon SaveWeapon;
	local Inventory Inv;
	local int x;

	if(bStoreAll) //final level, save all weapons
	{	
		for(Inv = Killed.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(CanSaveWeapon(Weapon(Inv)))
				Weapons[Weapons.length] = Weapon(Inv);
		}

		RPRI.OldWeaponHolder = Killed.Spawn(class'DruidsOldWeaponHolder', RPRI.Controller);
		RPRI.OldWeaponHolder.SelectedWeapon = Killed.Weapon;
		for(x = 0; x < Weapons.length; x++)
			StoreOldWeapon(Killed, RPRI.Controller, Weapons[x], RPRI.OldWeaponHolder);
	}
	else
	{
		SaveWeapon = Killed.Weapon;
		if(bStoreExtra) //AbilityLevel >= default.ExtraSavingLevel)
		{
			//when carrying the ball launcher, save the PendingWeapon (= old weapon)
			if(RPGBallLauncher(SaveWeapon) != None)
				SaveWeapon = RPGBallLauncher(SaveWeapon).RestoreWeapon;
			else if(RPGWeapon(SaveWeapon) != None && RPGBallLauncher(RPGWeapon(SaveWeapon).ModifiedWeapon) != None)
				SaveWeapon = RPGBallLauncher(RPGWeapon(SaveWeapon).ModifiedWeapon).RestoreWeapon;
		}
	
		if(CanSaveWeapon(SaveWeapon))
		{
			RPRI.OldWeaponHolder = Killed.Spawn(class'DruidsOldWeaponHolder', RPRI.Controller);
			RPRI.OldWeaponHolder.SelectedWeapon = Killed.Weapon;
			StoreOldWeapon(Killed, RPRI.Controller, SaveWeapon, RPRI.OldWeaponHolder);
		}
	}
}

static function RestoreOldWeapons(Pawn Other, RPGPlayerReplicationInfo RPRI)
{
	local bool bHasSelectedWeapon;
    local DruidsOldWeaponHolder.WeaponHolder Holder;
	
	if(RPRI != None && RPRI.OldWeaponHolder != None)
	{
		while(RPRI.OldWeaponHolder.WeaponHolders.length > 0)
		{
			Holder = RPRI.OldWeaponHolder.WeaponHolders[0];
			if(Holder.Weapon != None)
			{
				Holder.Weapon.GiveTo(Other); //somehow it can be destroyed.
				
				if(Holder.Weapon == None)
					continue;
				
				Holder.Weapon.AddAmmo(Holder.AmmoAmounts1 - Holder.Weapon.AmmoAmount(0), 0);
				Holder.Weapon.AddAmmo(Holder.AmmoAmounts2 - Holder.Weapon.AmmoAmount(1), 1);
				
				if(Holder.Weapon == RPRI.OldWeaponHolder.SelectedWeapon)
					bHasSelectedWeapon = true;
			}
			RPRI.OldWeaponHolder.WeaponHolders.Remove(0, 1);
		}
		
		if(bHasSelectedWeapon)
			RPRI.ClientSwitchToWeapon(RPRI.OldWeaponHolder.SelectedWeapon);
		
		RPRI.OldWeaponHolder.Destroy();
		return;
	}
}

static function StoreOldWeapon(Pawn Killed, Controller KilledController, Weapon Weapon, DruidsOldWeaponHolder OldWeaponHolder)
{
    Local DruidsOldWeaponHolder.WeaponHolder holder;

    if(Weapon == None)
        return;
		
    Weapon.SetOverlayMaterial(None, 0.0, True);
    if (WeaponAttachment(Weapon.ThirdPersonActor) != None)
      WeaponAttachment(Weapon.ThirdPersonActor).SetOverlayMaterial(None, 0.0, True);

    Weapon.DetachFromPawn(Killed);
    holder.Weapon = Weapon;
    holder.AmmoAmounts1 = Weapon.AmmoAmount(0);
    holder.AmmoAmounts2 = Weapon.AmmoAmount(1);

    OldWeaponHolder.WeaponHolders[OldWeaponHolder.WeaponHolders.length] = holder;

    Killed.DeleteInventory(holder.Weapon);
	
    //this forces the weapon to stay relevant to the player who will soon reclaim it
    holder.Weapon.SetOwner(KilledController);
    if (RPGWeapon(holder.Weapon) != None)
        RPGWeapon(holder.Weapon).ModifiedWeapon.SetOwner(KilledController);
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
	RequiredLevel=25
	ForbiddenWeaponTypes(0)=class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(2)=class'XWeapons.Painter'
	ForbiddenWeaponTypes(3)=class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(4)=class'UT2k4AssaultFull.Weapon_SpaceFighter'
	ForbiddenWeaponTypes(5)=class'UT2k4AssaultFull.Weapon_SpaceFighter_Skaarj'
	ForbiddenWeaponTypes(6)=class'UT2k4Assault.Weapon_Turret_Minigun' //however this should happen...
	ExtraSavingLevel=3
}
