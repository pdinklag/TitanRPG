//This message is sent to players who have some damage-causing condition (e.g. poison)
class HealedConditionMessage extends LocalMessage;

var localized string HealedMessage, HealedSelfMessage;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
				 optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if(RelatedPRI_1 == None)
		return "";

	if(RelatedPRI_2 == RelatedPRI_1)
		return default.HealedSelfMessage;
	else
		return Repl(default.HealedMessage, "$1", RelatedPRI_1.PlayerName);
}

defaultproperties
{
	HealedMessage="$1 has healed you!"
	HealedSelfMessage="You healed yourself!"
	bIsUnique=True
	bIsConsoleMessage=False
	bFadeMessage=True
	Lifetime=1
	DrawColor=(G=0,R=0)
	PosY=0.750000
}
