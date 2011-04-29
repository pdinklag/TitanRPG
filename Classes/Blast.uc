/*
	Interface for blasts such as Ultima, Mega Blast, Healing Bomb, etc. ~pd
*/
class Blast extends Actor
	config(TitanRPG)
	abstract;

var class<xEmitter> ChargeEmitterClass;
var class<Emitter> ExplosionClass; //wtf?? xEmitter and Emitter are two separate class chains and this fact cost me an hour >.< ~pd
var Sound ExplosionSound;

var config float Radius;

var config bool bBotsBeAfraid;
var config bool bAffectInstigator;
var config bool bAllowDeadInstigator;

var config float ChargeTime;

var xEmitter ChargeEmitter;
var bool bDoneCharging;

var AvoidMarker Fear;

var Controller InstigatorController;

simulated event Destroyed()
{
	if(Fear != None)
		Fear.Destroy();
		
	if(ChargeEmitter != None)
		ChargeEmitter.Destroy();

	Super.Destroyed();
}

simulated event PostBeginPlay()
{
	if(Role == ROLE_Authority)
		InstigatorController = Controller(Owner);
	
	Super.PostBeginPlay();
	
	if(Role == ROLE_Authority)
		ChargeEmitter = Spawn(ChargeEmitterClass);
	
	if(Role == ROLE_Authority && bBotsBeAfraid)
	{
		Fear = Spawn(class'AvoidMarker');
		Fear.SetCollisionSize(Radius, 200);
		Fear.StartleBots();
	}
	
	SetTimer(ChargeTime, false);
}

function SetChargeTime(float time)
{
	ChargeTime = time;
	SetTimer(ChargeTime, false);
	
	if(ChargeTime <= 0)
		Boom();
}

function Boom()
{
	MakeNoise(1.0);
	PlaySound(ExplosionSound);
	
	bDoneCharging = True; //must be done BEFORE (!!!!!) calling DoEffect because that will initiate Timer again
	
	if(Fear != None)
		Fear.Destroy();
		
	if(ChargeEmitter != None)
		ChargeEmitter.Destroy();
	
	if(Role == ROLE_Authority)
	{
		if(ExplosionClass != None)
			Spawn(ExplosionClass);
		
		DoEffect();
	}
}

simulated function Timer()
{
	if(!bDoneCharging)
	{
		if(Role == ROLE_Authority)
		{
			if(!bAllowDeadInstigator && (Instigator == None || Instigator.Health <= 0 || 
				(Instigator.Controller == None && Instigator.DrivenVehicle == None)))
			{
				Destroy();
				return;
			}
		}
		
		Boom();
	}
}

function DoEffect(); //this shall be overridden by subclassing blasts

defaultproperties
{
	bAffectInstigator=False
	bAllowDeadInstigator=False

	RemoteRole=ROLE_SimulatedProxy;
	
	ExplosionSound=Sound'WeaponSounds.redeemer_explosionsound'
	
	DrawType=DT_None
	TransientSoundVolume=1.000000
	TransientSoundRadius=5000.000000
	
	ChargeTime=2.000000
}
