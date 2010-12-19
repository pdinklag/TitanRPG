class ArtifactPickupTeleport extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactTeleport'
	PickupMessage="You got the Teleporter!"
	PickupSound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
	PickupForce="TranslocatorModuleRegeneration"
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'Weapons.TransBeacon'
	DrawScale=2.000000
}
