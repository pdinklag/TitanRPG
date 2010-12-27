class RPGReplicationInfo extends ReplicationInfo;

const MAX_ARTIFACTS = 63;

var int NumAbilities;
var class<RPGArtifact> Artifacts[MAX_ARTIFACTS];

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Artifacts, NumAbilities;
}

static function RPGReplicationInfo Get(LevelInfo Level)
{
	local RPGReplicationInfo RRI;
	
	foreach Level.DynamicActors(class'RPGReplicationInfo', RRI)
		return RRI;
}

defaultproperties
{
}
