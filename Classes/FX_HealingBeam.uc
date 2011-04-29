class FX_HealingBeam extends LinkBeamEffect;

var float LifeTime;

simulated function SetBeamLocation()
{
	StartEffect = Instigator.Location;
	SetLocation(StartEffect);
}

simulated function Vector SetBeamRotation()
{
	SetRotation(rotator(LinkedPawn.Location - Instigator.Location));
	return Normal(LinkedPawn.Location - Instigator.Location);
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
	
    if(Role == ROLE_Authority && (LinkedPawn == None || Instigator == None || Instigator.Controller == None) )
    {
        Destroy();
        return;
    }
	
	if(Role == ROLE_Authority)
	{
		LifeTime -= dt;
		if(LifeTime < 0.f)
		{
			Destroy();
			return;
		}
	}
	
	// set beam start location
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
}

defaultproperties
{
	Skins(0)=FinalBlend'XEffectMat.LinkBeamBlueFB'
	LifeTime=0.5
    LightHue=160
}
