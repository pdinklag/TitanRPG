class ArtifactPickupFlight extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactFlight'
	bAmbientGlow=False
	PickupMessage="You got the Flight artifact!"
	PickupSound=Sound'PickupSounds.SniperRiflePickup'
	PickupForce="SniperRiflePickup"
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.Flight'
	DrawScale=0.075000
	Physics=PHYS_Rotating
	RotationRate=(Yaw=24000)
}
