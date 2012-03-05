class ArtifactPickup_Flight extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_Flight'
	bAmbientGlow=False
	PickupMessage="You got the Flight artifact!"
	PickupSound=Sound'PickupSounds.SniperRiflePickup'
	PickupForce="SniperRiflePickup"
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'TitanRPG.ArtifactPickupStatics.Flight'
	DrawScale=0.075000
	Physics=PHYS_Rotating
	RotationRate=(Yaw=24000)
}
