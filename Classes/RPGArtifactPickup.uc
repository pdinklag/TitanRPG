class RPGArtifactPickup extends TournamentPickup;

function float DetourWeight(Pawn Other, float PathWeight) {
    return MaxDesireability/PathWeight;
}

defaultproperties {
	MaxDesireability=1.500000
	PickupSound=Sound'PickupSounds.SniperRiflePickup'
	PickupForce="SniperRiflePickup"
	AmbientGlow=128
	DrawType=DT_StaticMesh
	Physics=PHYS_Rotating
	RotationRate=(Yaw=24000)
}
