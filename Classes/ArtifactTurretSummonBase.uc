class ArtifactTurretSummonBase extends RPGDelayedUseArtifact
	abstract;

const MSG_NoMoreTurrets = 0x1000;
const MSG_CouldNotSpawn = 0x1001;

const MAX_FLOOR_DISTANCE = 256.0f;

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
	local Vehicle V;
	local vector SpawnLoc, HitNormal;
	
	SpawnLoc = Instigator.Location + 5.f * vector(Instigator.Rotation) * (Instigator.CollisionRadius + TurretClass.default.CollisionRadius);
	
	//Find floor
	if(Trace(SpawnLoc, HitNormal, SpawnLoc, SpawnLoc - MAX_FLOOR_DISTANCE * vect(0, 0, 1), false) != None)
		V = Spawn(TurretClass,,, SpawnLoc, Instigator.Rotation);
	
	if(V != None)
	{
		V.Instigator = Instigator;
		V.SetTeamNum(Instigator.Controller.GetTeamNum());
		V.bTeamLocked = false;
		
		if(!V.bNonHumanControl)
			V.EntryRadius = FMax(FMax(300.0, V.EntryRadius), 2.0 * V.CollisionRadius);
		
		if(V.IsA('ASVehicle_Sentinel'))
			ASVehicle_Sentinel(V).bSpawnCampProtection = true;

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
