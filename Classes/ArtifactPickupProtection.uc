class ArtifactPickupProtection extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactProtection'
	PickupMessage="You got the Protection!"
	PickupSound=Sound'PickupSounds.ShieldPack'
	PickupForce="ShieldPack"
	StaticMesh=StaticMesh'Editor.TexPropSphere'
	bAcceptsProjectors=False
	DrawScale=0.075000
	Skins(0)=Shader'<? echo($packageName); ?>.ArtifactPickupSkins.GlobeShader'
	AmbientGlow=255
}
