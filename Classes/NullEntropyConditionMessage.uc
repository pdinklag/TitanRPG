class NullEntropyConditionMessage extends LocalMessage;

var localized string NullEntropyMessage;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
				 optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	return Default.NullEntropyMessage;
}

defaultproperties
{
     NullEntropyMessage="Null Entropy"
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=2
     DrawColor=(B=219,G=0,R=154)
     PosY=0.750000
}
