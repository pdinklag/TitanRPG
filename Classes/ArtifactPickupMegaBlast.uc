class ArtifactPickupMegaBlast extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactMegaBlast'
	PickupMessage="You got the Mega Blast!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.MegaBlast'
	DrawScale=0.220000
}
