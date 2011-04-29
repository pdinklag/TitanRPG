class FX_Repulsion extends Emitter
	placeable;

defaultproperties
{
     Begin Object Class=MeshEmitter Name=MeshEmitter0
         StaticMesh=StaticMesh'AW-2k4XP.Weapons.ShockTankEffectRing'
         RenderTwoSided=True
         UseParticleColor=True
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=230,G=230,R=230,A=255))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255,A=255))
         ColorScale(2)=(RelativeTime=0.700000,Color=(B=230,G=230,R=230,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=30,G=30,R=30,A=10))
         FadeOutStartTime=0.600000
         FadeInEndTime=0.100000
         MaxParticles=1
         SpinsPerSecondRange=(X=(Max=1.000000),Y=(Max=1.000000),Z=(Max=1.000000))
         StartSpinRange=(Y=(Max=1.000000),Z=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.300000)
         SizeScale(1)=(RelativeTime=0.300000,RelativeSize=20.000000)
         SizeScale(2)=(RelativeTime=0.700000,RelativeSize=60.000000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=0.100000)
         StartSizeRange=(X=(Min=0.300000,Max=0.300000),Y=(Min=0.300000,Max=0.300000),Z=(Min=0.150000,Max=0.150000))
         InitialParticlesPerSecond=50000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.700000,Max=0.700000)
     End Object
     Emitters(0)=MeshEmitter'MeshEmitter0'

     Begin Object Class=MeshEmitter Name=MeshEmitter1
         StaticMesh=StaticMesh'AW-2k4XP.Weapons.ShockTankEffectRing'
         RenderTwoSided=True
         UseParticleColor=True
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=230,G=230,R=230,A=255))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255,A=255))
         ColorScale(2)=(RelativeTime=0.700000,Color=(B=230,G=230,R=230,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=30,G=30,R=30,A=10))
         FadeOutStartTime=0.600000
         FadeInEndTime=0.100000
         MaxParticles=1
         SpinsPerSecondRange=(X=(Max=2.000000),Y=(Max=2.000000),Z=(Max=2.000000))
         StartSpinRange=(Y=(Max=-1.000000),Z=(Max=-1.000000))
         SizeScale(0)=(RelativeSize=0.300000)
         SizeScale(1)=(RelativeTime=0.300000,RelativeSize=20.000000)
         SizeScale(2)=(RelativeTime=0.700000,RelativeSize=60.000000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=0.100000)
         StartSizeRange=(X=(Min=0.300000,Max=0.300000),Y=(Min=0.300000,Max=0.300000),Z=(Min=0.150000,Max=0.150000))
         InitialParticlesPerSecond=50000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.700000,Max=0.700000)
         InitialDelayRange=(Min=0.030000,Max=0.030000)
     End Object
     Emitters(1)=MeshEmitter'MeshEmitter1'

     AutoDestroy=True
     bNoDelete=False
     bNetTemporary=True
     RemoteRole=ROLE_DumbProxy
     Style=STY_Masked
     bDirectional=True
}
