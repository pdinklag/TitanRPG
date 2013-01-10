class RPGWeaponPickupModifier extends Info;

//Pickup
var WeaponPickup Pickup;
var class<RPGWeaponModifier> ModifierClass;
var class<WeaponAttachment> AttachmentClass;
var int ModifierLevel;

static function RPGWeaponPickupModifier Modify(WeaponPickup WP, RPGWeaponModifier WM) {
    local RPGWeaponPickupModifier WPM;

    WPM = WP.Spawn(class'RPGWeaponPickupModifier', WP);
    WPM.Pickup = WP;
    WPM.ModifierClass = WM.Class;
    WPM.ModifierLevel = WM.Modifier;
    
    if(WM.bIdentified && WM.default.ModifierOverlay != None && class<WeaponAttachment>(WM.Weapon.AttachmentClass) != None) {
        WPM.AttachmentClass = class<WeaponAttachment>(WM.Weapon.AttachmentClass);
        WPM.Enable('Tick');
    } else {
        WPM.Disable('Tick');
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

simulated event Tick(float dt) {
    if(AttachmentClass != None) {
        class'Sync_PickupModifier'.static.Sync(Pickup, ModifierClass, AttachmentClass);
    }
    
    Disable('Tick');
}

//Called when a pawn picks me up, simulates Touch, SpawnCopy, AnnouncePickup
function DoPickup(Pawn Other) {
    local Inventory Copy;

    Copy = Spawn(Pickup.InventoryType, Other);
    if(Copy != None) {
        Copy.GiveTo(Other, Pickup);
        Copy.PickupFunction(Other);
        
        if(Copy.IsA('Weapon')) {
            //apply modifier
            ModifierClass.static.Modify(Weapon(Copy), ModifierLevel, true);
        }
    }
    
    //TODO possibly modify message class and message
    Pickup.AnnouncePickup(Other);
    Pickup.Destroy();
    Destroy();
}

defaultproperties {
}
