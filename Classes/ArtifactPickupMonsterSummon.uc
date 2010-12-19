class ArtifactPickupMonsterSummon extends RPGArtifactPickup;

defaultproperties
{
	DrawScale=0.250000
	InventoryType=Class'ArtifactMonsterSummon'
	PickupMessage="You got the Summoning Charm!"
	StaticMesh=StaticMesh'<? echo($packageName); ?>.ArtifactPickupStatics.MonsterSummon'
}
