class LocalMessage_BotRole extends TeamSayMessagePlus;
//TODO CTF4

var localized array<string> RoleText;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	return RelatedPRI_1.PlayerName $ ":" @ default.RoleText[Switch];
}

defaultproperties {
    bBeep=False
    RoleText(0)="I'm a medic!";
}
