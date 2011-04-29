class ArtifactBioBomb extends RPGArtifact;

function BotWhatNext(Bot Bot)
{
	if(
		Instigator.Health >= 50 && //should survive until then
		CountNearbyEnemies(1536, true) >= 2
	)
	{
		Activate();
	}
}

function DoEffect()
{
	Spawn(class'Blast_Bio', Instigator.Controller,,Instigator.Location);
	Destroy();
}

defaultproperties
{
	bAllowInVehicle=False
	CostPerSec=75
	HudColor=(R=0)
	ArtifactID="BioBomb"
	Description="Causes a bio glob explosion."
	bCanBeTossed=False
	PickupClass=Class'ArtifactPickupBioBomb'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.biobomb'
	ItemName="Bio Bomb"
}
