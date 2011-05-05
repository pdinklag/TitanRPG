class ArtifactBase_Blast extends RPGArtifact
	abstract;

var config class<Blast> BlastClass;

var config int AIHealthMin, AIMinTargets;
var config bool bFriendly;

function BotWhatNext(Bot Bot)
{
	if(
		!HasActiveArtifact(Instigator) &&
		Bot.Adrenaline >= CostPerSec &&
		Instigator.Health >= AIHealthMin && //should survive until then
		CountNearbyEnemies(BlastClass.default.Radius, bFriendly) >= AIMinTargets
	)
	{
		Activate();
	}
}

function Blast SpawnBlast()
{
	return Spawn(BlastClass, Instigator.Controller,,Instigator.Location);
}

function DoEffect()
{
	SpawnBlast();
	Destroy(); //TODO
}

defaultproperties
{
	AIHealthMin=50
	AIMinTargets=2
	bFriendly=False
	
	bAllowInVehicle=False
	bCanBeTossed=False
}
