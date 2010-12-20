class ArtifactTurretSummonBase extends RPGDelayedUseArtifact
	abstract;

const MSG_NoMoreTurrets = 0x1000;
const MSG_CouldNotSpawn = 0x1001;

const MAX_FLOOR_DISTANCE = 512.0f;

var config class<Vehicle> TurretType;
var localized string NoMoreTurretsText, CouldNotSpawnText;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_NoMoreTurrets:
			return default.NoMoreTurretsText;
			
		case MSG_CouldNotSpawn:
			return default.CouldNotSpawnText;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

state Activated
{
	function DoEffect()
	{
		if(SpawnTurret(TurretType) == None)
		{
			if(Instigator.Controller != None)
				Instigator.Controller.Adrenaline += MinActivationTime * CostPerSec;
				
			Msg(MSG_CouldNotSpawn);
		}
	}
}

function BotWhatNext(Bot Bot)
{
	if(
		Bot.Adrenaline >= 25 &&
		FRand() < 0.5
	)
	{
		Activate();
	}
}

function bool CanActivate()
{
	local RPGPlayerReplicationInfo RPRI;

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
	
	if(RPRI != None && RPRI.Turrets.Length >= RPRI.MaxTurrets)
	{
		Msg(MSG_NoMoreTurrets);
		return false;
	}
	else
	{
		return Super.CanActivate();
	}
}

function Vehicle SpawnTurret(class<Vehicle> TurretClass)
{
	local RPGPlayerReplicationInfo RPRI;
	local RPGTurretController C;
	local Vehicle V;
	local vector SpawnLoc, HitLocation, HitNormal;
	local vector Dir;
	local Actor Floor;
	
	Dir = vector(Instigator.Rotation);
	Dir.Z = 0;
	
	SpawnLoc = Instigator.Location + 5.f * Normal(Dir) * (Instigator.CollisionRadius + TurretClass.default.CollisionRadius);
	
	V = Spawn(TurretClass,,, SpawnLoc + vect(0, 0, 256));
	
	Floor = V.Trace(HitLocation, HitNormal, V.Location - MAX_FLOOR_DISTANCE * vect(0, 0, 1), V.Location, false);
	if(Floor != None)
	{
		if(V.IsA('ASTurret') && ASTurret(V).TurretBase != None)
			HitLocation.Z += 0.5 * ASTurret(V).TurretBase.DrawScale * ASTurret(V).TurretBase.CollisionHeight;
		
		V.SetLocation(HitLocation);
	}
	else
	{
		V.Destroy();
	}
	
	if(V != None)
	{
		if(V.Controller != None)
			V.Controller.Destroy();
		
		C = Spawn(class'RPGTurretController');
		C.Master = Instigator.Controller;
		C.Possess(V);
	
		V.Instigator = Instigator;
		V.SetTeamNum(Instigator.Controller.GetTeamNum());
		V.bTeamLocked = false;
		
		if(!V.bNonHumanControl)
			V.EntryRadius = FMax(FMax(300.0, V.EntryRadius), 2.0 * V.CollisionRadius);
		
		if(V.IsA('ASVehicle_Sentinel'))
		{
			ASVehicle_Sentinel(V).bSpawnCampProtection = true;
		
			C.GotoState('Sleeping');
			C.Awake();
		}

		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
			RPRI.AddTurret(V);
	}

	return V;
}

defaultproperties
{
	CouldNotSpawnText="Failed to construct turret - adrenaline given back."
	NoMoreTurretsText="You cannot construct any more turrets at this time."
	bAllowInVehicle=False
	UseDelay=30
	MinActivationTime=1.000000
}
