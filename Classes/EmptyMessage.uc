//hack for RPGWeaponPickup so it doesn't actually give a pickup message
//the RPGWeapon itself does that (so it can display modifiers, etc. if appropriate)
class EmptyMessage extends LocalMessage;

static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
}

defaultproperties
{
     bIsConsoleMessage=False
}
