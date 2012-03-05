//=============================================================================
// TitanMisfortuneEffect - copy from Jailbreak's JBEmitterKillExplosion
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBEmitterKillExplosion.uc,v 1.1 2004-05-31 11:14:58 wormbo Exp $
//
// Emitter that creates an explosion effect.
//=============================================================================

class FX_Misfortune extends Emitter;

var Sound MisfortuneSound;

//=============================================================================
// PostBeginPlay
//
// Handle low framerate conditions.
//=============================================================================

simulated event PostBeginPlay()
{
  PlaySound(MisfortuneSound, SLOT_Interact, 1.0,, 300);
  if ( Level.bDropDetail )
    LightRadius = 5;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
	MisfortuneSound=Sound'TitanRPG.SoundEffects.Explosion'
     Begin Object Class=SpriteEmitter Name=ExplosionParticles
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         FadeOutStartTime=0.200000
         MaxParticles=20
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=20.000000,Max=50.000000)
         StartSpinRange=(X=(Max=65535.000000),Y=(Max=65535.000000),Z=(Max=65535.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=0.700000,RelativeSize=1.000000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=40.000000,Max=60.000000),Y=(Min=40.000000,Max=60.000000),Z=(Min=40.000000,Max=60.000000))
         InitialParticlesPerSecond=1000.000000
         Texture=Texture'XEffects.Skins.fexpt'
         LifetimeRange=(Min=0.500000,Max=1.000000)
         StartVelocityRadialRange=(Min=-20.000000,Max=-10.000000)
         VelocityLossRange=(X=(Min=2.000000,Max=2.500000),Y=(Min=2.000000,Max=2.500000),Z=(Min=2.000000,Max=2.500000))
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(0)=SpriteEmitter'ExplosionParticles'

     AutoDestroy=True
     LightType=LT_FadeOut
     LightEffect=LE_QuadraticNonIncidence
     LightHue=28
     LightSaturation=90
     LightBrightness=255.000000
     LightRadius=7.000000
     LightPeriod=32
     LightCone=128
     bNoDelete=False
     bDynamicLight=True
     bNetTemporary=True
     RemoteRole=ROLE_SimulatedProxy
}
