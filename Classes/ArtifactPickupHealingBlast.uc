class ArtifactPickupHealingBlast extends RPGArtifactPickup;

defaultproperties
{
	InventoryType=Class'ArtifactHealingBlast'
	PickupMessage="You got the Healing Bomb!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.HealingBomb'
	DrawScale=0.220000
}
