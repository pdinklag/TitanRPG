class FX_SuperSpeedTrail extends SpeedTrail;

var float Speed; //how long to fade from one color to another
var array<Color> Colors;

var float Counter;
var int CurrentColor;
var float R, G, B;
var float xR, xG, xB;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	R = Colors[0].R;
	G = Colors[0].G;
	B = Colors[0].B;
	NextColor();
}

simulated function NextColor()
{
	CurrentColor++;
	if(CurrentColor >= Colors.Length)
		CurrentColor = 0;
	
	Counter = Speed;
	
	xR = (1 / Speed) * (float(Colors[CurrentColor].R) - R);
	xG = (1 / Speed) * (float(Colors[CurrentColor].G) - G);
	xB = (1 / Speed) * (float(Colors[CurrentColor].B) - B);
}

simulated event Tick(float dt)
{
	Super.Tick(dt);

	R = FMax(0.0, FMin(255.0, R + xR * dt));
	G = FMax(0.0, FMin(255.0, G + xG * dt));
	B = FMax(0.0, FMin(255.0, B + xB * dt));
	
	mColorRange[0].R = byte(R);
	mColorRange[0].G = byte(G);
	mColorRange[0].B = byte(B);
	mColorRange[1] = mColorRange[0];
	
	Counter -= dt;
	if(Counter <= 0)
		NextColor();
}

defaultproperties
{
	Colors(0)=(R=255,G=255,B=0)	//YELLOW
	Colors(1)=(R=0,G=255,B=0)		//GREEN
	Colors(2)=(R=0,G=255,B=255)	//AQUA
	Colors(3)=(R=0,G=0,B=255)		//BLUE
	Colors(4)=(R=255,G=0,B=255)	//MAGENTA
	Colors(5)=(R=255,G=0,B=0)		//RED
	Speed=1.000000
    Skins(0)=Texture'TitanRPG.Effects.Trail'
    mColorRange(0)=(R=255,G=255,B=255,A=255)
    mColorRange(1)=(R=255,G=255,B=255,A=255)
}
