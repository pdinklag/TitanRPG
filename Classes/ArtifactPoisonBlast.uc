class ArtifactPoisonBlast extends RPGArtifact;

function BotWhatNext(Bot Bot)
{
	if(
		Instigator.Health >= 50 && //should survive until then
		CountNearbyEnemies(class'Blast_Poison'.default.Radius) >= 2
	)
	{
		Activate();
	}
}

function DoEffect()
{
	Spawn(class'Blast_Poison', Instigator.Controller,,Instigator.Location);
	Destroy();
}

defaultproperties
{
	bAllowInVehicle=False
	CostPerSec=150
	HudColor=(R=0)
	ArtifactID="PoisonBlast"
	Description="Poisons nearby enemies."
	bCanBeTossed=False
	PickupClass=Class'ArtifactPickupPoisonBlast'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.poisonblast'
	ItemName="Poison Blast"
}
