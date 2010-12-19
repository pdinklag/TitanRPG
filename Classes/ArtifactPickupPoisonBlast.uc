class ArtifactPickupPoisonBlast extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactPoisonBlast'
	PickupMessage="You got the Poison Blast!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.PoisonBlast'
	DrawScale=0.220000
}
