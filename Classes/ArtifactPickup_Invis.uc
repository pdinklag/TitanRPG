class ArtifactPickup_Invis extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_Invis'
	PickupMessage="You got the Invisibility!"
	PickupSound=Sound'PickupSounds.SniperAmmoPickup'
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.Invis2M'
	DrawScale=0.50
}
