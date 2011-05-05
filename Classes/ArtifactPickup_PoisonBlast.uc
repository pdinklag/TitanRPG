class ArtifactPickup_PoisonBlast extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_PoisonBlast'
	PickupMessage="You got the Poison Blast!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.PoisonBlast'
	DrawScale=0.220000
}
