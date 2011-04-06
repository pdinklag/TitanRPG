class RPGEffectMessage extends LocalMessage abstract;

var localized string EffectMessageString, EffectMessageCauserString, EffectMessageSelfString;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, //victim
	optional PlayerReplicationInfo RelatedPRI_2, //causer
	optional Object OptionalObject
)
{
	if(RelatedPRI_2 != None)
	{
		if(RelatedPRI_2 == RelatedPRI_1)
			return default.EffectMessageSelfString;
		else
			return Repl(default.EffectMessageCauserString, "$1", RelatedPRI_2.PlayerName);
	}
	else
	{
		return default.EffectMessageString;
	}
}

static function Color GetColor(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2
)
{
    return default.DrawColor;
}

defaultproperties
{
	bIsUnique=True
	bIsConsoleMessage=False
	bFadeMessage=True
	PosY=0.750000
	Lifetime=2

	DrawColor=(B=255,G=255,B=255,A=255)

	EffectMessageString="RPGEffect"
	EffectMessageSelfString="RPGEffect by yourself"
	EffectMessageCauserString="RPGEffect by $1"
}
