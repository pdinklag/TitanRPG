class RPGWeaponPickupModifier extends Info;

//Pickup
var WeaponPickup Pickup;
var class<RPGWeaponModifier> ModifierClass;
var class<WeaponAttachment> AttachmentClass;
var int ModifierLevel;
var bool bIdentified;

static function RPGWeaponPickupModifier Modify(WeaponPickup WP, RPGWeaponModifier WM) {
    local RPGWeaponPickupModifier WPM;

    WPM = WP.Spawn(class'RPGWeaponPickupModifier', WP);
    WPM.Pickup = WP;
    WPM.ModifierClass = WM.Class;
    WPM.ModifierLevel = WM.Modifier;
    WPM.bIdentified = WM.bIdentified;
    
    if(WPM.bIdentified && WM.default.ModifierOverlay != None && class<WeaponAttachment>(WM.Weapon.AttachmentClass) != None) {
        WPM.AttachmentClass = class<WeaponAttachment>(WM.Weapon.AttachmentClass);
        WPM.Sync();
    }
    
    return WPM;
}

static function RPGWeaponPickupModifier GetFor(WeaponPickup WP) {
	local RPGWeaponPickupModifier WPM;

	if(WP != None)
	{
		foreach WP.ChildActors(class'RPGWeaponPickupModifier', WPM)
			return WPM;
	}
	return None;
}

static function SimulateWeaponPickup(WeaponPickup Pickup, Pawn Other, class<RPGWeaponModifier> ModifierClass, int ModifierLevel, bool bIdentify, optional bool bForceGive) {
    local Weapon Copy;
    
    Pickup.TriggerEvent(Pickup.Event, Pickup, Other);
    
    if(bForceGive) {
        //force give to using pickup only (weapon is created in the process
        Copy = class'Util'.static.ForceGiveTo(Other, None, Pickup);
    } else {
        Copy = Weapon(Pickup.SpawnCopy(Other));
    }
    
    Pickup.AnnouncePickup(Other);
    Pickup.SetRespawn();
    
    if(Copy != None) {
        Copy.PickupFunction(Other);
        
        if(ModifierClass != None) {
            ModifierClass.static.Modify(Copy, ModifierLevel, bIdentify, true);
        }
    }
}
static function bool SimulateWeaponLocker(WeaponLocker Locker, Pawn Other, class<RPGWeaponModifier> ModifierClass, int ModifierLevel, bool bIdentify) {
    local Weapon Copy;
    local RPGWeaponModifier WM;
    local int i, x;
    
    //Find entry
    x = -1;
    for(i = 0; i < Locker.Weapons.Length; i++) {
        if(Locker.Weapons[i].WeaponClass == Locker.InventoryType) {
            x = i;
            break;
        }
    }
    
    if(x >= 0) {
        //Simulate weapon locker
        Copy = Weapon(Locker.SpawnCopy(Other));
        if (Copy != None) {
            Copy.PickupFunction(Other);
            if (Locker.Weapons[x].ExtraAmmo > 0) {
                Copy.AddAmmo(Locker.Weapons[x].ExtraAmmo, 0);
            }

            if(ModifierClass != None) {
                WM = ModifierClass.static.Modify(Copy, ModifierLevel, true);
            }
        }

        return true;
    } else {
        return false;
    }
}

event Tick(float dt) {
    if(Pickup == None) {
        Destroy();
    }
}

function Sync() {
    class'Sync_PickupModifier'.static.Sync(Pickup, ModifierClass, AttachmentClass);
}

defaultproperties {
}
