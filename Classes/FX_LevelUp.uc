//Cool particle effect that appears on players who just leveled up
class FX_LevelUp extends Emitter;

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if (Level.NetMode == NM_Client)
		Initialize();
}

simulated function Initialize()
{
	if (Level.NetMode == NM_DedicatedServer)
	{
		LifeSpan = 6.0;
	}
	else if (DrawScale > 1.0)
	{
		/*Emitters[0].StartLocationRange.X.Min *= DrawScale;
		Emitters[0].StartLocationRange.X.Max *= DrawScale;
		Emitters[0].StartLocationRange.Y.Min *= DrawScale;
		Emitters[0].StartLocationRange.Y.Max *= DrawScale;*/
		Emitters[0].StartLocationPolarRange.Z.Max *= DrawScale;
		Emitters[0].StartLocationPolarRange.Z.Min *= DrawScale;
		Emitters[0].InitialParticlesPerSecond *= DrawScale;
	}
}

simulated function Tick(float deltaTime)
{
	//hackish way to increase max particles since MaxParticles is const
	if (Emitters[0].Initialized)
	{
		Emitters[0].MaxActiveParticles *= DrawScale;
		Emitters[0].Particles.Length = Emitters[0].MaxActiveParticles;
		disable('Tick');
	}
}

defaultproperties
{
	Begin Object Class=SpriteEmitter Name=SpriteEmitter1
		UseColorScale=True
		FadeOut=True
		RespawnDeadParticles=False
		UniformMeshScale=False
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=0.200000,Color=(G=170,R=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(G=120,R=255))
		FadeOutStartTime=0.800000
		CoordinateSystem=PTCS_Relative
		MaxParticles=500
		StartLocationOffset=(Y=45.000000)
		StartLocationShape=PTLS_Polar
		StartLocationPolarRange=(Y=(Max=65536.000000),Z=(Min=25.000000,Max=25.000000))
		RevolutionsPerSecondRange=(Z=(Min=0.200000,Max=0.200000))
		UseRotationFrom=PTRS_Offset
		RotationOffset=(Roll=16384)
		StartSizeRange=(X=(Min=5.000000,Max=5.000000),Y=(Min=5.000000,Max=5.000000),Z=(Min=5.000000,Max=5.000000))
		InitialParticlesPerSecond=200.000000
		Texture=Texture'EpicParticles.Flares.Sharpstreaks2'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.000000,Max=2.500000)
		StartVelocityRange=(Y=(Min=-50.000000,Max=-50.000000))
	End Object
	Emitters(0)=SpriteEmitter'SpriteEmitter1'

	AutoDestroy=True
	bNoDelete=False
	bTrailerSameRotation=True
	bReplicateMovement=False
	Physics=PHYS_Trailer
	RemoteRole=ROLE_SimulatedProxy
	CollisionRadius=25.000000
	bBlockZeroExtentTraces=False
	bBlockNonZeroExtentTraces=False
}
