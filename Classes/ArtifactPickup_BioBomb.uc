class ArtifactPickup_BioBomb extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_BioBomb'
	PickupMessage="You got the Bio Bomb!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.BioBomb'
	DrawScale=0.220000
}
