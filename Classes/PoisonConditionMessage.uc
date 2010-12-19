class PoisonConditionMessage extends LocalMessage;

var localized string PoisonMessage;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
				 optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if (Switch == 0)
		return Default.PoisonMessage;
}

defaultproperties
{
	PoisonMessage="You are poisoned!"
	bIsUnique=True
	bIsConsoleMessage=False
	bFadeMessage=True
	Lifetime=2
	DrawColor=(B=0,R=0)
	PosY=0.750000
}
