class ArtifactPickup_Protection extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'Artifact_Protection'
	PickupMessage="You got the Protection!"
	PickupSound=Sound'PickupSounds.ShieldPack'
	PickupForce="ShieldPack"
	StaticMesh=StaticMesh'Editor.TexPropSphere'
	bAcceptsProjectors=False
	DrawScale=0.075000
	Skins(0)=Shader'TitanRPG.ArtifactPickupSkins.GlobeShader'
	AmbientGlow=255
}
