//
// Message for gaining a level
//
//	RelatedPRI_1 is the one who gained a level.
//	Switch is that player's new level.
//

class LocalMessage_LevelUp extends LocalMessage;

var(Message) localized string LevelString, SomeoneString;

static function color GetConsoleColor( PlayerReplicationInfo RelatedPRI_1 )
{
    return class'HUD'.Default.WhiteColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject 
	)
{
	local string Name;

	if (RelatedPRI_1 == None)
		Name = Default.SomeoneString;
	else
		Name = RelatedPRI_1.PlayerName;

	return Name$Default.LevelString$Switch$".";
}

defaultproperties
{
	LevelString=" is now Level "
	SomeoneString=" someone "
	bIsSpecial=False
	DrawColor=(B=0,G=0)
}
