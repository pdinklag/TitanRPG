class ArtifactPickup_FreezeBomb extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_FreezeBomb'
	PickupMessage="You got the Freeze Bomb!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.FreezeBomb'
	DrawScale=0.220000
}
