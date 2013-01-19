class RPGTotemIndicator extends Actor;

defaultproperties {
    bFixedRotationDir=True
    Physics=PHYS_Rotating
	RotationRate=(Yaw=24000)

    bAlwaysRelevant=True
    NetUpdateFrequency=1
    RemoteRole=ROLE_DumbProxy

    DrawType=DT_StaticMesh
}
