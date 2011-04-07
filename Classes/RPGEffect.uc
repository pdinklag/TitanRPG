/*
	Generic effect class.
	Used for Poison, Freeze, Null Entropy, etc...
*/
class RPGEffect extends Inventory
	config(TitanRPG)
	abstract;

//Immunity
var config array<class<Pawn> > ImmunePawnTypes;

/*
	Harmful effects can be nullified with the Magic Nullifying modifier
	and cannot affect teammates.
*/
var config bool bHarmful;

var config bool bAllowOnSelf;
var config bool bAllowOnFlagCarriers;
var config bool bAllowOnVehicles;
var config bool bAllowStacking;

//Effect
var Controller EffectCauser;
var config float Duration;

var float Modifier;

var config float TimerInterval;

//Audiovisual
var Sound EffectSound;
var Material EffectOverlay;
var class<XEmitter> EmitterClass;

var xEmitter Emitter; //client-only

var class<RPGEffectMessage> EffectMessageClass;

//Timing
var bool bStart;
var float LastStartTime;

replication
{
	unreliable if(Role == ROLE_Authority)
		Duration,
		ClientSpawnEffect;
	
	reliable if(Role == ROLE_Authority && bNetDirty)
		EffectCauser;
}

static function bool CanBeApplied(Pawn Other, optional Controller Causer, optional float Modifier)
{
	//Stacking
	if(!default.bAllowStacking && GetFor(Other) != None)
		return false;

	//Spawn Protection
	if(default.bHarmful &&
		Other.Level.TimeSeconds <= Other.SpawnTime + DeathMatch(Other.Level.Game).SpawnProtectionTime)
	{
		return false;
	}

	//Self
	if(!default.bAllowOnSelf && Causer == Other.Controller)
		return false;

	//Teammates
	if(default.bHarmful && Causer != None && Causer != Other.Controller && Causer.SameTeamAs(Other.Controller))
		return false;
	
	//TODO: weapon, abilities

	//Magic Nullifying modifier
	if(default.bHarmful && WeaponMagicNullifier(Other.Weapon) != None)
		return false;

	//Vehicles
	if(!default.bAllowOnVehicles && Other.IsA('Vehicle'))
		return false;

	//Immune pawn types
	if(class'Util'.static.ClassInArray(Other.class, default.ImmunePawnTypes) >= 0)
		return false;
	
	//Flag carriers
	if(
		!default.bAllowOnFlagCarriers &&
		Other.PlayerReplicationInfo != None &&
		Other.PlayerReplicationInfo.HasFlag != None
	)
	{
		return false;
	}
	
	return true;
}

static function RPGEffect Create(Pawn Other, optional Controller Causer, optional float OverrideDuration, optional float NewModifier)
{
	local RPGEffect Effect;
	
	if(CanBeApplied(Other, Causer, NewModifier))
	{
		Effect = GetFor(Other);
		if(Effect != None)
		{
			//Update
			Effect.Stop();
			
			Effect.EffectCauser = Causer;
			
			if(OverrideDuration > 0)
				Effect.Duration = Max(Effect.Duration, OverrideDuration);
			
			if(NewModifier > Effect.Modifier)
				Effect.Modifier = NewModifier;
		}
		else
		{
			//Create
			Effect = Other.Spawn(default.class, Other);
			Effect.GiveTo(Other);
			
			if(Effect != None)
			{
				Effect.EffectCauser = Causer;
			
				if(OverrideDuration > 0.0f)
					Effect.Duration = OverrideDuration;
				
				if(NewModifier > Effect.Modifier)
					Effect.Modifier = NewModifier;
			}
		}
	}
	
	return Effect;
}

static function RemoveAll(Pawn Other)
{
	local Inventory Inv;
	local RPGEffect Effect;
	
	Inv = Other.Inventory;
	while(Inv != None)
	{
		Effect = RPGEffect(Inv);
		Inv = Inv.Inventory;
		
		if(Effect != None)
			Effect.Destroy();
	}
}

static function Remove(Pawn Other)
{
	local Inventory Inv;
	
	Inv = Other.FindInventoryType(default.class);
	if(Inv != None)
		Inv.Destroy();
}

static function RPGEffect GetFor(Pawn Other)
{
	local RPGEffect Effect;
	
	Effect = RPGEffect(Other.FindInventoryType(default.class));
	if(Effect != None && Effect.IsInState('Activated'))
		return Effect;
	else
		return None;
}

function Start()
{
	GotoState('Activated');
}

function Stop();

state Activated
{
	function BeginState()
	{
		if(EffectSound != None && Level.TimeSeconds - LastStartTime > 0.5f) //avoid sounds being spammed like hell
			class'Util'.static.PlayLoudEnoughSound(Instigator, EffectSound);
		
		if(EffectOverlay != None)
			class'SyncOverlayMaterial'.static.Sync(Instigator, EffectOverlay, Duration, false);
		
		LastStartTime = Level.TimeSeconds;
		
		SetTimer(TimerInterval, true);
		Timer();
	}
	
	function Timer()
	{
		local PlayerReplicationInfo CauserPRI;
		
		if(EffectCauser != None)
			CauserPRI = EffectCauser.PlayerReplicationInfo;

		if(EffectMessageClass != None)
			Instigator.ReceiveLocalizedMessage(EffectMessageClass, 0, Instigator.PlayerReplicationInfo, CauserPRI);

		if(EmitterClass != None)
			ClientSpawnEffect();
	}
	
	event Tick(float dt)
	{
		if(Instigator == None || Instigator.Health <= 0)
		{
			Destroy();
			return;
		}
		
		if(bStart)
		{
			Timer();
			bStart = false;
		}
	
		Duration -= dt;
		
		if(Duration <= 0)
			Destroy();
	}
	
	function EndState()
	{
		SetTimer(0, false);
	}
	
	function Start();
	
	function Stop()
	{
		GotoState('');
	}
}

simulated function ClientSpawnEffect()
{
	if(Instigator != None && EmitterClass != None)
		Instigator.Spawn(EmitterClass,,, Instigator.Location, Instigator.Rotation);
}

defaultproperties
{
	Duration=1.00
	TimerInterval=1.00

	bHarmful=True
	bAllowOnSelf=True
	bAllowOnFlagCarriers=True
	bAllowOnVehicles=False
	bAllowStacking=True
	
	bReplicateInstigator=True
	bOnlyRelevantToOwner=False
}
