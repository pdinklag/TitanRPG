class FX_Beam extends LinkBeamEffect;

var Actor Source;
var vector LinkedLocation;

replication {
    reliable if(Role == ROLE_Authority && bNetInitial)
        Source, LinkedLocation;
}

simulated event PostBeginPlay() {
    if(Role == ROLE_Authority) {
        Source = Owner;
    }
    
    Super.PostBeginPlay();
}

simulated function SetBeamLocation()
{
	StartEffect = Source.Location;
	SetLocation(StartEffect);
}

simulated function Vector SetBeamRotation() {
    SetRotation(rotator(LinkedLocation - Source.Location));
    return Normal(LinkedLocation - Source.Location);
}

simulated function bool CheckMaxEffectDistance(PlayerController P, vector SpawnLocation)
{
	return true;
}

//Rewrite
simulated function Tick(float dt)
{
    local float LocDiff, RotDiff, WiggleMe;
    local Vector BeamDir;
	
    if(Role == ROLE_Authority && (Source == None))
    {
        Destroy();
        return;
    }
	
	// determine target location
    if(LinkedPawn != None) {
        LinkedLocation = LinkedPawn.Location;
    }
    
    // set beam start location
    SetBeamLocation();
    BeamDir = SetBeamRotation();

    if ( Level.bDropDetail || Level.DetailMode == DM_Low )
    {
        bDynamicLight = false;
        LightType = LT_None;
    } else if ( bDynamicLight ) {
        LightType = LT_Steady;
    }

    EndEffect = LinkedLocation;
    mSpawnVecA = LinkedLocation;
    mWaveLockEnd = bLockedOn || (LinkColor > 0);

    LocDiff			= VSize((Location - PrevLoc) * Vect(1,1,5));
    RotDiff			= VSize(Vector(Rotation) - Vector(PrevRot));
    WiggleMe		= FMax(LocDiff*0.02, RotDiff*4.0);
    mWaveAmplitude	= FMax(1.0, mWaveAmplitude - mWaveAmplitude*1.0*dt);
    mWaveAmplitude	= FMin(16.0, mWaveAmplitude + WiggleMe);

    PrevLoc = Location;
    PrevRot = Rotation;
}

defaultproperties
{
    bReplicateInstigator=False

	Skins(0)=FinalBlend'XEffectMat.LinkBeamGreenFB'
	LifeSpan=0.5
    LightHue=160
    mBendStrength=3.0
}
