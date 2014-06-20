/*
    Synchronizer for modified pickups.
*/
class Sync_PickupModifier extends Sync;

var WeaponPickup Target;

var class<WeaponAttachment> AttachmentClass;
var class<RPGWeaponModifier> ModifierClass;

replication
{
	reliable if(Role == ROLE_Authority)
		Target, AttachmentClass, ModifierClass;
}

static function Sync_PickupModifier Sync(WeaponPickup Pickup, class<RPGWeaponModifier> ModifierClass, Class<WeaponAttachment> AttachmentClass)
{
    local Sync_PickupModifier Sync;

    Sync = Pickup.Spawn(class'Sync_PickupModifier');
    Sync.Target = Pickup;
    Sync.ModifierClass = ModifierClass;
    Sync.AttachmentClass = AttachmentClass;

    //server
    if(Pickup.DrawType != DT_Mesh) {
        Pickup.LinkMesh(AttachmentClass.default.Mesh);
        Pickup.SetDrawType(DT_Mesh);
        
        if(ClassIsChildOf(AttachmentClass, class'xWeaponAttachment') &&
            AttachmentClass.default.DrawScale != class'xWeaponAttachment'.default.DrawScale) {
        
            Pickup.SetDrawScale(AttachmentClass.default.DrawScale);
        }
        
        Pickup.SetRotation(Pickup.Rotation + rot(0, 0, 32768) + AttachmentClass.default.RelativeRotation);
    }
    Sync.ClientFunction();

    return Sync;
}

simulated function bool ClientFunction() {
	if(Target == None) {
		return false;
	} else {
        Target.bOrientOnSlope = false;
        Target.Skins = AttachmentClass.default.Skins;
		Target.SetOverlayMaterial(ModifierClass.default.ModifierOverlay, 1000000, true);
		return true;
	}
}

function bool ShouldDestroy() {
    if(Target == None) {
        return true;
    } else {
        return false;
    }
}

defaultproperties {
    LifeSpan=60
}
