class Radiation extends Emitter;

var float DamageRadius;
var float DamageInterval;
var float DamageCore;
var float DamageAmbient;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if(Role == ROLE_Authority)
	{
		LightRadius = int(DamageRadius / 32.0f);
		bLightChanged = true;
		
		SetTimer(DamageInterval, true);
	}
}

function Timer()
{
	local int Damage;
	local Actor x;
	
	foreach VisibleCollidingActors(class'Actor', x, DamageRadius)
	{
		Damage = int(DamageAmbient + DamageCore * (1.f - VSize(x.Location - Location) / DamageRadius));

		if(Damage >= 0)
			x.TakeDamage(Damage, Instigator, x.Location, vect(0, 0, 0), class'DamTypeRadiation');
	}
}

defaultproperties
{
	//TODO: Geiger counter as ambient sound

	DamageRadius=256
	DamageInterval=1.0f
	DamageCore=10.0f
	DamageAmbient=5.0f
	LifeSpan=10.0f
	
	AutoDestroy=True
	
	LightType=LT_Steady
	LightBrightness=192
	LightSaturation=128
	LightHue=80
	LightRadius=15
    bDynamicLight=True
	bLightChanged=True
	
	bStatic=False
	bNoDelete=False

	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
	
	DrawType=DT_Sprite
	Texture=S_Light
}
