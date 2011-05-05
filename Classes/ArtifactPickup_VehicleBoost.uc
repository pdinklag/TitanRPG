class ArtifactPickup_VehicleBoost extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_VehicleBoost'
	PickupMessage="You got the Nitro Boost!"
	StaticMesh=StaticMesh'AS_Decos.HellbenderEngine'
	PickupSound=Sound'<? echo($packageName); ?>.SoundEffects.NitroPickup'
	DrawScale=0.500000
}
