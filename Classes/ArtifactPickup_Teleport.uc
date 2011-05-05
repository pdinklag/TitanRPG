class ArtifactPickup_Teleport extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_Teleport'
	PickupMessage="You got the Teleporter!"
	PickupSound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
	PickupForce="TranslocatorModuleRegeneration"
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'Weapons.TransBeacon'
	DrawScale=2.000000
}
