class ArtifactPickup_MegaBlast extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_MegaBlast'
	PickupMessage="You got the Mega Blast!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.MegaBlast'
	DrawScale=0.220000
}
