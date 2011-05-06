class Artifact_SummonMonster extends ArtifactBase_Summon;

struct MonsterTypeStruct
{
	var class<Monster> MonsterClass;
	var string DisplayName;
	var int Cost;
	var int Cooldown;
};
var config array<MonsterTypeStruct> MonsterTypes;

const MSG_MaxMonsters = 0x1000;

var localized string MsgMaxMonsters;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_MaxMonsters:
			return default.MsgMaxMonsters;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	if(SelectedOption < 0)
		CostPerSec = 0; //no cost until selection

	if(!Super.CanActivate())
		return false;
	
	if(InstigatorRPRI.Monsters.Length >= InstigatorRPRI.MaxMonsters)
	{
		Msg(MSG_MaxMonsters);
		return false;
	}
	
	return true;
}

function Actor SpawnActor(class<Actor> SpawnClass, vector SpawnLoc, rotator SpawnRot)
{
	local FriendlyMonsterController C;
	local Monster M;
	
	M = Monster(Super.SpawnActor(SpawnClass, SpawnLoc, SpawnRot));
	if(M != None)
	{
		if(M.Controller != None)
			M.Controller.Destroy();

		C = Spawn(class'FriendlyMonsterController',,, SpawnLoc, Instigator.Rotation);
		C.Possess(M);
		C.SetMaster(Instigator.Controller);
		
		if(InstigatorRPRI != None)
			InstigatorRPRI.AddMonster(M);
	}
	return M;
}

function OnSelection(int i)
{
	CostPerSec = MonsterTypes[i].Cost;
	Cooldown = MonsterTypes[i].Cooldown;
	SpawnActorClass = MonsterTypes[i].MonsterClass;
}

simulated function int GetNumOptions()
{
	return MonsterTypes.Length;
}

simulated function string GetOption(int i)
{
	return MonsterTypes[i].DisplayName;
}

defaultproperties
{
	MsgMaxMonsters="You cannot spawn any more monsters at this time."

	bSelection=true

	ArtifactID="MonsterSummon"
	Description="Summons a friendly monster of your choice."
	ItemName="Summoning Charm"
	PickupClass=Class'ArtifactPickup_MonsterSummon'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.MonsterSummon'
	HudColor=(B=96,G=64,R=192)
	CostPerSec=0
	Cooldown=0

	MonsterTypes(0)=(MonsterClass=class'SkaarjPack.SkaarjPupae',DisplayName="Skaarj Pupae",Cost=10,Cooldown=5)
	MonsterTypes(1)=(MonsterClass=class'SkaarjPack.Krall',DisplayName="Krall",Cost=25,Cooldown=5)
	MonsterTypes(2)=(MonsterClass=class'SkaarjPack.Brute',DisplayName="Brute",Cost=50,Cooldown=5)
	MonsterTypes(3)=(MonsterClass=class'SkaarjPack.Warlord',DisplayName="Warlord",Cost=75,Cooldown=10)
}
