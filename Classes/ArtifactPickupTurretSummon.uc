class ArtifactPickupTurretSummon extends RPGArtifactPickup;

defaultproperties
{
	DrawScale=0.250000
	InventoryType=Class'ArtifactTurretSummon'
	PickupMessage="You got the Turret Constructor!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.MonsterSummon'
}
