/*
	Due to OverlayMaterial being only replicated unreliably (see Actor),
	often people do not receive it properly and thus cannot see an Actor's overlay.

	However, in RPG, overlays can be pretty important (e.g. Invulnerability),
	so this class serves as a secure method to set an overlay on an actor.
*/

class Sync_OverlayMaterial extends Sync;

var Actor target;
var Material mat;
var float time;
var bool bOverride;

replication
{
	reliable if(Role == ROLE_Authority)
		target, mat, time, bOverride;
}

static function Sync_OverlayMaterial Sync(Actor target, Material mat, float time, optional bool bOverride)
{
	local Sync_OverlayMaterial Sync;

	Sync = target.Spawn(class'Sync_OverlayMaterial');
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
