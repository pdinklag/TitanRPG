class ArtifactBase_Beacon extends RPGArtifact
    abstract
    HideDropDown;

var class<RPGArtifactBeacon> BeaconClass;
var RPGArtifactBeacon LastBeacon;

function BeaconLanded(RPGArtifactBeacon Beacon); //abstract, called when beacon landed
function BeaconDestroyed(RPGArtifactBeacon Beacon); //abstract, called when beacon got destroyed prematurely

function RPGArtifactBeacon SpawnBeacon()
{
	local RPGArtifactBeacon Beacon;

	Beacon = Instigator.Spawn(BeaconClass, Instigator.Controller,, Instigator.Location + Instigator.EyePosition(), Instigator.Controller.Rotation);
	if(Beacon != None)
		Beacon.Artifact = Self;
	
	return Beacon;
}

function bool DoEffect()
{
	return (SpawnBeacon() != None);
}

defaultproperties
{
	BeaconClass=class'RPGArtifactBeacon'

	CostPerSec=10
	MinActivationTime=0
	bAllowInVehicle=False
}
