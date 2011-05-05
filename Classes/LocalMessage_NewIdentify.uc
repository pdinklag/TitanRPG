class LocalMessage_NewIdentify extends LocalMessage;

var(Message) localized string IdentifyString, PickupString;

static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject)
{
	if(RPGWeaponModifier(OptionalObject) != None && RPGWeaponModifier(OptionalObject).Weapon != None)
		Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

static function Color GetConsoleColor(PlayerReplicationInfo RelatedPRI_1)
{
    return class'HUD'.Default.WhiteColor;
}

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
				 optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if(Switch == 0)
		return Repl(default.IdentifyString, "$W", RPGWeaponModifier(OptionalObject).Weapon.ItemName);
	else
		return Repl(default.PickupString, "$W", RPGWeaponModifier(OptionalObject).Weapon.ItemName);
}

defaultproperties
{
	IdentifyString="Your weapon is a $W!"
	PickupString="You got the $W."
	bIsUnique=True
	bFadeMessage=True
	PosY=0.800000
}
