class ColoredTrail extends SpeedTrail;

var Color Color;

replication
{
	reliable if(Role == ROLE_Authority && bNetDirty)
		Color;
}

simulated event Tick(float dt)
{
	Super.Tick(dt);
	
	mColorRange[0] = Color;
	mColorRange[1] = Color;
}

defaultproperties
{
	Color=(R=255,G=255,B=255,A=255)
    Skins(0)=Texture'<? echo($packageName); ?>.Effects.Trail'
}
