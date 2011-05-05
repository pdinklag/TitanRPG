class ArtifactBase_Summon extends ArtifactBase_Beacon abstract;

var config class<Actor> SpawnActorClass;

function Actor SpawnActor(class<Actor> SpawnClass, vector SpawnLoc, rotator SpawnRot)
{
	return Instigator.Spawn(SpawnClass,,, SpawnLoc, SpawnRot);
}

function BeaconLanded(RPGArtifactBeacon Beacon)
{
	local class<Actor> SummonClass;
	local Actor A;
	local vector SpawnLoc, SpawnDir;
	
	SpawnLoc = Beacon.Location;
	SummonClass = SummonBeacon(Beacon).SummonClass;
	
	SpawnDir = VRand();
	SpawnDir.Z = 0;
	
	A = SpawnActor(SummonClass, SpawnLoc, rotator(SpawnDir));
	if(A == None)
	{
		Log("Failed to spawn" @ SummonClass);
	}
}

function RPGArtifactBeacon SpawnBeacon()
{
	local RPGArtifactBeacon Beacon;
	
	Beacon = Super.SpawnBeacon();
	if(Beacon != None)
		SummonBeacon(Beacon).SummonClass = SpawnActorClass;
	
	return Beacon;
}

defaultproperties
{
	BeaconClass=class'SummonBeacon'
}
