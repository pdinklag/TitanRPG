class TeamBoosterMessage extends ComboMessage;

var localized string MessageText, DisabledMessage;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject 
	)
{
	if(Switch == 0)
		return Repl(default.MessageText, "$1", RelatedPRI_1.PlayerName);
	else
		return Repl(default.DisabledMessage, "$1", RelatedPRI_1.PlayerName);
}

defaultproperties
{
	MessageText="Team Booster by $1!"
	DisabledMessage="$1 is already boosting your team!"
	Lifetime=5 //little longer than the usual message
}
