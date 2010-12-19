class ComboDroneMessage extends LocalMessage;

var localized string NoMoreDronesText;

static function Color GetConsoleColor( PlayerReplicationInfo RelatedPRI_1 )
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
	if(Switch == 0)
		return default.NoMoreDronesText;
	
	return "";
}

defaultproperties
{
	NoMoreDronesText="You cannot spawn any more Drones!"
	bIsSpecial=False
	DrawColor=(B=0,G=0)
}
