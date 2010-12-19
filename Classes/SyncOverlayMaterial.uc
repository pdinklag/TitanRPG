/*
	Due to OverlayMaterial being only replicated unreliably (see Actor),
	often people do not receive it properly and thus cannot see an Actor's overlay.

	However, in RPG, overlays can be pretty important (e.g. Invulnerability),
	so this class serves as a secure method to set an overlay on an actor.
*/

class SyncOverlayMaterial extends Sync;

var Actor target;
var Material mat;
var float time;
var bool bOverride;

replication
{
	reliable if(Role == ROLE_Authority)
		target, mat, time, bOverride;
}

static function SyncOverlayMaterial Sync(Actor target, Material mat, float time, optional bool bOverride)
{
	local SyncOverlayMaterial Sync;

	Sync = target.Spawn(class'SyncOverlayMaterial');
	Sync.target = target;
	Sync.mat = mat;
	
	if(time < 0)
		time = 1000000; //a million aka indefinitely
	
	Sync.time = time;
	Sync.bOverride = bOverride;
	
	//server
	target.SetOverlayMaterial(mat, time, bOverride);
	
	return Sync;
}

simulated function bool ClientFunction()
{
	if(target == None)
	{
		return false;
	}
	else
	{
		target.SetOverlayMaterial(mat, time, bOverride);
		return true;
	}
}

defaultproperties
{
	Lifetime = 9999.00 //for a LONG while
}
