class Blast_Bio extends Blast;

var config int NumGlobs;
var config float GlobSpeedMin, GlobSpeedMax;

function DoEffect()
{
	local BioBombGlob Glob;
	local int i;
	
	for(i = 0; i < NumGlobs; i++)
	{
		Glob = Instigator.Spawn(class'BioBombGlob',,, Location, rotator(VRand()));
		
		if(Glob != None)
			Glob.Velocity = vector(Glob.Rotation) * (GlobSpeedMin + FRand() * (GlobSpeedMax - GlobSpeedMin));
	}
	
	Destroy();
}

defaultproperties
{
	GlobSpeedMin=500
	GlobSpeedMax=1250
	NumGlobs=200
	
	bBotsBeAfraid=True
	ChargeTime=2.00
	Radius=1536
	ChargeEmitterClass=class'FX_BlastCharger_Bio'
	ExplosionClass=None
	ExplosionSound=None //none necessary really
}
