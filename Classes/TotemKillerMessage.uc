class TotemKillerMessage extends xKillerMessagePlus;

var localized string YourTotemKilled;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject 
	)
{
	if(RelatedPRI_2 == None || OptionalObject == None || !OptionalObject.IsA('Pawn'))
		return "";

	if(RelatedPRI_2.PlayerName != "")
		return default.YourTotemKilled @ RelatedPRI_2.PlayerName @ default.YouKilledTrailer;
}

defaultproperties
{
	YourTotemKilled="Your Totem killed"
}
