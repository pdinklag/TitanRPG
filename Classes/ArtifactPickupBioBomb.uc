class ArtifactPickupBioBomb extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactBioBomb'
	PickupMessage="You got the Bio Bomb!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.BioBomb'
	DrawScale=0.220000
}
