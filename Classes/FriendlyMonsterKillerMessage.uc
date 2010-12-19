class FriendlyMonsterKillerMessage extends xKillerMessagePlus;

var localized string YourMonsterKilled;

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
		return default.YourMonsterKilled @ RelatedPRI_2.PlayerName @ default.YouKilledTrailer;
}

defaultproperties
{
	YourMonsterKilled="Your Monster killed"
}
