class RPGLinkTrail extends NewLinkTrail;

var color TeamColors[4];
var color TeamColorsTwo[4];

function TeamColorAdjust(int TeamIndex)
{
    if ( Emitters[1] != None )
    {
        Emitters[1].ColorScale[1].Color = TeamColors[TeamIndex];
        Emitters[1].ColorScale[2].Color = TeamColorsTwo[TeamIndex];
    }
    if ( Emitters[0] != None )
    {
        Emitters[0].ColorScale[0].Color = TeamColors[TeamIndex];
        Emitters[0].ColorScale[1].Color = TeamColorsTwo[TeamIndex];
    }
}

defaultproperties
{
     TeamColors(0)=(R=255)
     TeamColors(1)=(B=255)
     TeamColors(2)=(G=255)
     TeamColors(3)=(G=255,R=255)
     TeamColorsTwo(0)=(R=255)
     TeamColorsTwo(1)=(B=255)
     TeamColorsTwo(2)=(G=255)
     TeamColorsTwo(3)=(G=255,R=255)
     Begin Object Class=SpriteEmitter Name=SpriteEmitter21
         UseDirectionAs=PTDU_Right
         UseColorScale=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(R=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         StartLocationOffset=(X=30.000000)
         StartSizeRange=(X=(Min=-80.000000,Max=-80.000000),Y=(Min=30.000000,Max=30.000000))
         InitialParticlesPerSecond=5000.000000
         Texture=Texture'AW-2004Particles.Weapons.PlasmaShaft'
         LifetimeRange=(Min=0.010000,Max=0.010000)
         StartVelocityRange=(X=(Min=-10.000000,Max=-10.000000))
         WarmupTicksPerSecond=1.000000
         RelativeWarmupTime=1.000000
     End Object
     Emitters(0)=SpriteEmitter'RPGLinkTrail.SpriteEmitter21'

}
