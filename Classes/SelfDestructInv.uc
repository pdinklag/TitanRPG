class SelfDestructInv extends Inventory;

var Vehicle V;
var Controller Boesetaeter; //or Uebelwicht?

var Sound TickSound;

var class<Emitter> ExplosionEffectClass;
var Sound ExplosionSound;

//from artifact
var int CountdownTime;
var float DamageRadius;
var int Damage;
var float MomentumTransfer;

var localized string ActivationText;

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super.GiveTo(Other, Pickup);
	
	if(Vehicle(Other) == None)
		Destroy();
		
	SetTimer(1.0, true);
}

function Timer()
{
	local Actor Victims;
	local Emitter E;

	if(--CountdownTime == 0)
	{
		//BOOM!
		E = Spawn(ExplosionEffectClass,,, V.Location, Rot(0,16384,0));
		if(Level.NetMode == NM_DedicatedServer)
		{
			E.LifeSpan = 0.7;
		}
		V.PlaySound(ExplosionSound,,1.5 * Instigator.TransientSoundVolume,,Instigator.TransientSoundRadius);
		
		foreach V.VisibleCollidingActors(class'Actor', Victims, DamageRadius, Instigator.Location)
		{
			if(Victims != V && Victims.Role == ROLE_Authority)
			{
				if(
					Pawn(Victims) != None && 
					Pawn(Victims).Controller != None &&
					Pawn(Victims).Controller != Boesetaeter &&
					Pawn(Victims).Controller.SameTeamAs(Boesetaeter)
				)continue;
					
				Victims.TakeDamage(
					float(Damage) * (1.0 - VSize(Victims.Location - V.Location) / DamageRadius),
					Boesetaeter.Pawn,
					Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * Normal(Victims.Location - V.Location),
					MomentumTransfer * Normal(Victims.Location - V.Location),
					class'DamTypeSelfDestruct'
				);
			}
		}
		
		V.Health = 0; //"hack" to make the vehicle die even after you left it
		V.TakeDamage(
			V.HealthMax,
			Boesetaeter.Pawn,
			V.Location,
			MomentumTransfer * 0.25 * vect(0,0,1),
			class'DamTypeSelfDestruct'
		);
		
		Destroy();
	}
	else
	{
		V.PlaySound(TickSound,, Instigator.TransientSoundVolume,,Instigator.TransientSoundRadius);
		V.ReceiveLocalizedMessage(class'UnrealGame.StringMessagePlus', CountdownTime, None, None, Class);
	}
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	return Repl(default.ActivationText, "$1",
		Switch @ class'MutTitanRPG'.static.GetSecondsText(Switch));
}

defaultproperties
{
	ActivationText="Self Destruction in T minus $1..."
	ExplosionEffectClass=Class'FX_SelfDestructExplosion'
	ExplosionSound=Sound'ONSVehicleSounds-S.Explosions.Explosion01'
	TickSound=Sound'GeneralAmbience.beep4'

	CountdownTime=3
	Damage=1000
	DamageRadius=750.000000
	MomentumTransfer=50000.000000
}