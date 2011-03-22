class ArtifactPickupLightningRod extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactLightningRod'
	PickupMessage="You got the Lightning Rod!"
	PickupSound=Sound'PickupSounds.SniperAmmoPickup'
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.Rod'
	DrawScale=0.250000
}
