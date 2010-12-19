class TeamBoosterMessage extends ComboMessage;

var localized string MessageText;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject 
	)
{
	return Repl(default.MessageText, "$1", RelatedPRI_1.PlayerName);
}

defaultproperties
{
	MessageText="Team Booster by $1!"
	Lifetime=5 //little longer than the usual message
}
