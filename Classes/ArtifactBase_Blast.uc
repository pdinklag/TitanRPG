class ArtifactBase_Blast extends RPGArtifact
	abstract
    HideDropDown;

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

function bool DoEffect()
{
	local Blast Blast;

	Blast = SpawnBlast();
	
	return (Blast != None);
}

defaultproperties
{
	bChargeUp=True

	AIHealthMin=50
	AIMinTargets=2
	bFriendly=False
	
	bAllowInVehicle=False
	bCanBeTossed=False
	
	MaxUses=1
}
