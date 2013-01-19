class FX_Beam extends LinkBeamEffect;

var Actor Source;

replication {
    reliable if(Role == ROLE_Authority && bNetInitial)
        Source;
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

simulated function Vector SetBeamRotation()
{
    SetRotation(rotator(LinkedPawn.Location - Source.Location));
    return Normal(LinkedPawn.Location - Source.Location);
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
	
    if(Role == ROLE_Authority && (LinkedPawn == None || Source == None) )
    {
        Destroy();
        return;
    }
	
	// set beam start location
    if(LinkedPawn != None) {
        SetBeamLocation();
        BeamDir = SetBeamRotation();

        if ( Level.bDropDetail || Level.DetailMode == DM_Low )
        {
            bDynamicLight = false;
            LightType = LT_None;
        }
        else if ( bDynamicLight )
            LightType = LT_Steady;

        if ( LinkedPawn != None )
            EndEffect = LinkedPawn.Location;

        mSpawnVecA = EndEffect;
        mWaveLockEnd = bLockedOn || (LinkColor > 0);

        LocDiff			= VSize((Location - PrevLoc) * Vect(1,1,5));
        RotDiff			= VSize(Vector(Rotation) - Vector(PrevRot));
        WiggleMe		= FMax(LocDiff*0.02, RotDiff*4.0);
        mWaveAmplitude	= FMax(1.0, mWaveAmplitude - mWaveAmplitude*1.0*dt);
        mWaveAmplitude	= FMin(16.0, mWaveAmplitude + WiggleMe);

        PrevLoc = Location;
        PrevRot = Rotation;
    } else {
        Destroy();
    }
}

defaultproperties
{
    bReplicateInstigator=False

	Skins(0)=FinalBlend'XEffectMat.LinkBeamGreenFB'
	LifeSpan=0.5
    LightHue=160
    mBendStrength=3.0
}
