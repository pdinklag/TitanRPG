class FX_Flight extends Emitter;

var bool bKillNow;

replication
{
	reliable if (bNetDirty && Role == ROLE_Authority)
		bKillNow;
}

function BeginPlay()
{
	Super.BeginPlay();

	if (Instigator == None)
		Destroy();
	else if (Level.NetMode != NM_DedicatedServer)
		SetOffsets();
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Level.NetMode != NM_DedicatedServer)
	{
		Emitters[0].InitialDelay = FRand();
		Emitters[1].InitialDelay = FRand();
	}
}

simulated function PostNetReceive()
{
	if (bKillNow)
		Kill();
	else if (Instigator != None)
		SetOffsets();
}

simulated function SetOffsets()
{
	Instigator.PlayAnim('Jump_Mid');
	Emitters[0].StartLocationOffset = Instigator.GetBoneCoords('lfoot').Origin - Instigator.Location;
	Emitters[1].StartLocationOffset = Instigator.GetBoneCoords('rfoot').Origin - Instigator.Location;
}

simulated function Kill()
{
	Super.Kill();
	bKillNow = true;

	if (Level.NetMode == NM_DedicatedServer)
		SetTimer(3, false);
}

function Timer()
{
	Destroy();
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=192,R=192,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,A=255))
         FadeOutStartTime=1.500000
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=5.000000,Max=5.000000)
         UseRotationFrom=PTRS_Actor
         StartSizeRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
         InitialParticlesPerSecond=5.000000
         Texture=Texture'EpicParticles.Flares.Sharpstreaks2'
         LifetimeRange=(Min=2.000000,Max=2.000000)
         StartVelocityRange=(Z=(Min=-15.000000,Max=-15.000000))
     End Object
     Emitters(0)=SpriteEmitter'SpriteEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=192,R=192,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,A=255))
         FadeOutStartTime=1.500000
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=5.000000,Max=5.000000)
         UseRotationFrom=PTRS_Actor
         StartSizeRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
         InitialParticlesPerSecond=5.000000
         Texture=Texture'EpicParticles.Flares.Sharpstreaks2'
         LifetimeRange=(Min=2.000000,Max=2.000000)
         StartVelocityRange=(Z=(Min=-15.000000,Max=-15.000000))
     End Object
     Emitters(1)=SpriteEmitter'SpriteEmitter1'

     AutoDestroy=True
     bNoDelete=False
     bTrailerSameRotation=True
     bReplicateInstigator=True
     bReplicateMovement=False
     Physics=PHYS_Trailer
     RemoteRole=ROLE_SimulatedProxy
     bBlockZeroExtentTraces=False
     bBlockNonZeroExtentTraces=False
     bNetNotify=True
}
