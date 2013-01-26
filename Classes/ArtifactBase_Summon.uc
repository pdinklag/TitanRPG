class ArtifactBase_Summon extends ArtifactBase_Beacon
    abstract
    HideDropDown;

var config class<Actor> SpawnActorClass;

var bool bShowFailureMessage;
var float RestoreAdrenaline;

const MSG_FailedToSpawn = 0x0200;

var localized string MsgFailedToSpawn;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_FailedToSpawn:
			return default.MsgFailedToSpawn;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}


function Actor SpawnActor(class<Actor> SpawnClass, vector SpawnLoc, rotator SpawnRot)
{
	return Instigator.Spawn(SpawnClass, Instigator.Controller,, SpawnLoc, SpawnRot);
}

function Failed()
{
    if(bShowFailureMessage) {
        Msg(MSG_FailedToSpawn);
    }

	//Give back adrenaline
	if(RestoreAdrenaline > 0)
	{
		Instigator.Controller.Adrenaline =
			Min(Instigator.Controller.AdrenalineMax, Instigator.Controller.Adrenaline + RestoreAdrenaline);
	}
	
	//reset cooldown
	if(NextUseTime > Level.TimeSeconds)
		ForceCooldown(0);
}

function BeaconLanded(RPGArtifactBeacon Beacon)
{
	local class<Actor> SummonClass;
	local Actor A;
	local vector SpawnLoc, SpawnDir;
	
	if(Instigator != None)
	{
		SpawnLoc = Beacon.Location;
		SummonClass = SummonBeacon(Beacon).SummonClass;
		
		SpawnDir = VRand();
		SpawnDir.Z = 0;
		
		A = SpawnActor(SummonClass, SpawnLoc, rotator(SpawnDir));
		if(A == None)
			Failed();
	}
}

function BeaconDestroyed(RPGArtifactBeacon Beacon)
{
	Failed();
}

function RPGArtifactBeacon SpawnBeacon()
{
	local RPGArtifactBeacon Beacon;
	
	Beacon = Super.SpawnBeacon();
	if(Beacon != None)
	{
		SummonBeacon(Beacon).SummonClass = SpawnActorClass;
		RestoreAdrenaline = CostPerSec;
	}
	
	return Beacon;
}

function BotWhatNext(Bot Bot) {
	if(FRand() < 0.5) {
		Activate();
	}
}

defaultproperties
{
	MsgFailedToSpawn="Failed to spawn."
	BeaconClass=class'SummonBeacon'
    bShowFailureMessage=True
}
