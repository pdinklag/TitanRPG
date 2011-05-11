class LocalMessage_LevelTeleporter extends LocalMessage;

var(Message) localized string Text;

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
	return Repl(default.Text, "$1", Switch);
}

defaultproperties
{
	Text="You need to be at least level $1 in order to use this teleporter."
	bIsSpecial=False
	DrawColor=(B=0,G=0)
}
