class ArtifactMonsterSummonBase extends RPGDelayedUseArtifact
	abstract;

const MSG_NoMoreMonsters = 0x1000;
const MSG_CouldNotSpawn = 0x1001;

var config class<Monster> MonsterType;
var localized string NoMoreMonstersText, CouldNotSpawnText;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_NoMoreMonsters:
			return default.NoMoreMonstersText;
			
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
		if(SpawnMonster(MonsterType) == None)
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
	
	if(RPRI != None && RPRI.Monsters.Length >= RPRI.MaxMonsters)
	{
		Msg(MSG_NoMoreMonsters);
		return false;
	}
	else
	{
		return Super.CanActivate();
	}
}

function Monster SpawnMonster(class<Monster> MonsterClass)
{
	local RPGPlayerReplicationInfo RPRI;
	local FriendlyMonsterController C;
	local Monster M;
	local vector SpawnLoc;
	
	SpawnLoc = Instigator.Location + 5.f * vector(Instigator.Rotation) * (Instigator.CollisionRadius + MonsterClass.default.CollisionRadius);
	SpawnLoc.Z = SpawnLoc.Z + Instigator.CollisionHeight - MonsterClass.default.CollisionHeight;
	
	M = Spawn(MonsterClass,,, SpawnLoc, Instigator.Rotation);
	if(M != None)
	{
		if(M.Controller != None)
			M.Controller.Destroy();

		C = Spawn(class'FriendlyMonsterController',,, SpawnLoc, Instigator.Rotation);
		C.Possess(M);
		C.SetMaster(Instigator.Controller);
		
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
			RPRI.AddMonster(M);
	}

	return M;
}

defaultproperties
{
	CouldNotSpawnText="Failed to spawn monster - adrenaline given back."
	NoMoreMonstersText="You cannot spawn any more monsters at this time."
	bAllowInVehicle=False
	UseDelay=30
	MinActivationTime=1.000000
}
