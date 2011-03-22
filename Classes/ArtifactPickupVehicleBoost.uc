class ArtifactPickupVehicleBoost extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactVehicleBoost'
	PickupMessage="You got the Nitro Boost!"
	StaticMesh=StaticMesh'AS_Decos.HellbenderEngine'
	PickupSound=Sound'<? echo($packageName); ?>.SoundEffects.NitroPickup'
	DrawScale=0.500000
}
