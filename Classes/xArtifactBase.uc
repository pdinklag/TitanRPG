class xArtifactBase extends xPickUpBase placeable;

var() class<RPGArtifact> ArtifactType;

simulated event PostBeginPlay()
{
	if(ArtifactType != None)
		PowerUp = ArtifactType.default.PickupClass;

    Super.PostBeginPlay();
	
	SetLocation(Location + vect(0, 0, -1));
}

defaultproperties
{
	bDelayedSpawn=False

    DrawScale=0.8
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'XGame_rc.AmmoChargerMesh'
	SpiralEmitter=class'XEffects.Spiral'

    CollisionRadius=60.000000
    CollisionHeight=6.000000
}
