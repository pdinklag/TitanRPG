//for the "player level" page in the RPG menu, spawned for each RPRI
class RPGPlayerLevelInfo extends ReplicationInfo;

var PlayerReplicationInfo PRI;
var int RPGLevel, ExpNeeded;
var float Experience;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		PRI;

	unreliable if(Role == ROLE_Authority && bNetDirty)
		RPGLevel, Experience, ExpNeeded;
}

static function RPGPlayerLevelInfo GetFor(PlayerReplicationInfo OwnerPRI)
{
	local RPGPlayerLevelInfo PLI;

	foreach OwnerPRI.DynamicActors(class'RPGPlayerLevelInfo', PLI)
	{
		if(PLI.PRI == OwnerPRI)
			return PLI;
	}
	return None;
}

defaultproperties
{
}
