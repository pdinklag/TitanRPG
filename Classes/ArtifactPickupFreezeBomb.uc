class ArtifactPickupFreezeBomb extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactFreezeBomb'
	PickupMessage="You got the Freeze Bomb!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.FreezeBomb'
	DrawScale=0.220000
}
