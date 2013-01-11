class RPGWeaponPickupModifier extends Info;

//Pickup
var WeaponPickup Pickup;
var class<RPGWeaponModifier> ModifierClass;
var class<WeaponAttachment> AttachmentClass;
var int ModifierLevel;

var bool bPickupWasHidden;
var bool bRandomize;

static function RPGWeaponPickupModifier Modify(WeaponPickup WP, RPGWeaponModifier WM) {
    local RPGWeaponPickupModifier WPM;

    WPM = WP.Spawn(class'RPGWeaponPickupModifier', WP);
    WPM.Pickup = WP;
    WPM.ModifierClass = WM.Class;
    WPM.ModifierLevel = WM.Modifier;
    
    if(WM.bIdentified && WM.default.ModifierOverlay != None && class<WeaponAttachment>(WM.Weapon.AttachmentClass) != None) {
        WPM.AttachmentClass = class<WeaponAttachment>(WM.Weapon.AttachmentClass);
        WPM.Sync();
    }
    
    return WPM;
}

static function RPGWeaponPickupModifier Randomize(WeaponPickup WP) {
    local RPGWeaponPickupModifier WPM;

    WPM = WP.Spawn(class'RPGWeaponPickupModifier', WP);
    WPM.Pickup = WP;
    WPM.AttachmentClass = class<WeaponAttachment>(WP.InventoryType.default.AttachmentClass);
    WPM.bRandomize = true;

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

event Tick(float dt) {
    if(Pickup == None) {
        Destroy();
    }
}

function Sync() {
    class'Sync_PickupModifier'.static.Sync(Pickup, ModifierClass, AttachmentClass);
}

//Called when a pawn picks me up, simulates Touch, SpawnCopy, AnnouncePickup
function DoPickup(Pawn Other) {
    local Weapon Copy;
    
    //Simulate pickup
    Copy = Weapon(Pickup.SpawnCopy(Other));
    if(Copy != None) {
        Copy.PickupFunction(Other);
        if(bRandomize) {
            //TODO: PDP protection
            ModifierClass = class'MutTitanRPG'.static.Instance(Level).GetRandomWeaponModifier(
                class<Weapon>(Pickup.InventoryType), Other);
                
            ModifierLevel = -100;
        }
        
        if(ModifierClass != None) {
            ModifierClass.static.Modify(Copy, ModifierLevel, true);
        }
    }

    Pickup.AnnouncePickup(Other);
    Pickup.SetRespawn();
    
    if(Pickup == None || Pickup.bDeleteMe) {
        Destroy();
    }
}

defaultproperties {
}
