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

var localized string MsgMaxMonsters, SelectionTitle;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReceiveMonsterType;
}

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

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int i;

	Super.GiveTo(Other, Pickup);
	
	for(i = 0; i < MonsterTypes.Length; i++) {
		ClientReceiveMonsterType(i, MonsterTypes[i]);
    }
}

simulated function ClientReceiveMonsterType(int i, MonsterTypeStruct M)
{
    if(Role < ROLE_Authority) {
        if(i == 0)
            MonsterTypes.Length = 0;

        MonsterTypes[i] = M;
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

simulated function string GetSelectionTitle()
{
	return SelectionTitle;
}

simulated function int GetNumOptions()
{
	return MonsterTypes.Length;
}

simulated function string GetOption(int i)
{
	return MonsterTypes[i].DisplayName;
}

simulated function int GetOptionCost(int i) {
	return MonsterTypes[i].Cost;
}

function int SelectBestOption() {
    local Controller C;
    local int i;
    
    C = Instigator.Controller;
    if(C != None) {
        //The AI assumes that the best options are listed last
        for(i = MonsterTypes.Length - 1; i >= 0; i--) {
            if(C.Adrenaline >= MonsterTypes[i].Cost && FRand() < 0.5) {
                return i;
            }
        }
        
        //None
        return -1;
    } else {
        return Super.SelectBestOption();
    }
}

defaultproperties
{
	SelectionTitle="Pick a monster to summon:"
	MsgMaxMonsters="You cannot spawn any more monsters at this time."

	bSelection=true

	ArtifactID="MonsterSummon"
	Description="Summons a friendly monster of your choice."
	ItemName="Summoning Charm"
	PickupClass=Class'ArtifactPickup_MonsterSummon'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.MonsterSummon'
	HudColor=(B=96,G=64,R=192)
	CostPerSec=0
	Cooldown=0

	MonsterTypes(0)=(MonsterClass=class'SkaarjPack.SkaarjPupae',DisplayName="Skaarj Pupae",Cost=10,Cooldown=5)
	MonsterTypes(1)=(MonsterClass=class'SkaarjPack.Krall',DisplayName="Krall",Cost=25,Cooldown=5)
	MonsterTypes(2)=(MonsterClass=class'SkaarjPack.Brute',DisplayName="Brute",Cost=50,Cooldown=5)
	MonsterTypes(3)=(MonsterClass=class'SkaarjPack.Warlord',DisplayName="Warlord",Cost=75,Cooldown=10)
}
