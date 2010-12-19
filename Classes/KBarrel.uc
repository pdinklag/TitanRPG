class KBarrel extends NetKActor;

defaultproperties
{
	StaticMesh=StaticMesh'AS_Decos.ExplodingBarrel'
	
    bBlockedPath=false
    bCriticalObject=false
    DamageSpeed=550
    HitDamageScale=0.7
    RelativeImpactVolume=240
    bShoveable=true
    ShoveModifier=1.4
    bDramaticLighting=false

	Begin Object Class=KarmaParams Name=KParams0
		KMass=0.75
		KStartEnabled=True
		bHighDetailOnly=False
		bKDoubleTickRate=True
		bKAllowRotate=True
		bDoSafetime=True
		KFriction=10.000000
		KRestitution=0.100000
		KImpactThreshold=100.000000
	End Object
	KParams=KarmaParams'KBarrel.KParams0'
	
	bNoDelete=False
	bStatic=False
}
