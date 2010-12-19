class ArtifactPickupMakeMagicWeapon extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactMakeMagicWeapon'
	PickupMessage="You got the Magic Weapon Maker!"
	PickupSound=Sound'PickupSounds.ShieldPack'
	PickupForce="ShieldPack"
	StaticMesh=StaticMesh'XPickups_rc.UDamagePack'
	bAcceptsProjectors=False
	DrawScale=0.100000
	Skins(0)=Shader'AWGlobal.Shaders.LiquidCoolant'
	AmbientGlow=255
}
