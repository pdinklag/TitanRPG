class ArtifactMonsterSummon extends ArtifactMonsterSummonBase;

struct MonsterTypeStruct
{
	var class<Monster> MonsterClass;
	var string DisplayName;
	var int Cost;
};
var config array<MonsterTypeStruct> MonsterTypes;

var config bool bUseCostAsCooldown; //instead of consuming adrenaline, use the Cost as a cooldown value instead

var int PickedMonster;

replication
{
	reliable if(Role == ROLE_Authority)
		bUseCostAsCooldown;

	reliable if(Role == ROLE_Authority)
		ClientShowMenu, ClientClearMonsterTypes, ClientReceivePickableMonster;

	reliable if(Role < ROLE_Authority)
		ServerPickMonster;
}

simulated function int PickBest()
{
	local int i, Cost, Best, BestCost;
	
	Best = -1;
	BestCost = 0;
	
	for(i = 0; i < MonsterTypes.Length; i++)
	{
		Cost = MonsterTypes[i].Cost;
		if(Cost <= Instigator.Controller.Adrenaline && Cost > BestCost)
		{
			Best = i;
			BestCost = Cost;
		}
	}
	return Best;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int i;

	Super.GiveTo(Other, Pickup);
	
	if(Level.NetMode == NM_DedicatedServer)
	{
		ClientClearMonsterTypes();
		for(i = 0; i < MonsterTypes.Length; i++)
			ClientReceivePickableMonster(MonsterTypes[i]);
	}
}

simulated function ClientClearMonsterTypes()
{
	if(MonsterTypes.Length > 0)
		MonsterTypes.Remove(0, MonsterTypes.Length);
}

simulated function ClientReceivePickableMonster(MonsterTypeStruct Type)
{
	MonsterTypes[MonsterTypes.Length] = Type;
}

simulated function ClientShowMenu()
{
	class'MonsterSummonMenu'.static.ShowFor(Self);
}

function ServerPickMonster(int i)
{
	PickedMonster = i;
	
	if(i >= 0)
	{
		MonsterType = MonsterTypes[i].MonsterClass;
		
		if(!bUseCostAsCooldown)
			CostPerSec = MonsterTypes[i].Cost;
		
		Activate();
	}
}

function bool CanActivate()
{
	local bool b;
	
	b = Super.CanActivate();
	if(PickedMonster >= 0 && !b)
	{
		PickedMonster = -1;
		
		if(!bUseCostAsCooldown)
			CostPerSec = 0;
	}
	
	return b;
}

state Activated
{
	function BeginState()
	{
		if(PickedMonster >= 0)
		{
			Super.BeginState();
		}
		else
		{
			GotoState('');
		
			if(Instigator.Controller.IsA('PlayerController'))
				ClientShowMenu();
			else
				ServerPickMonster(PickBest());
		}
	}
	
	function EndState()
	{
		if(PickedMonster >= 0)
		{
			Super.EndState();

			if(bUseCostAsCooldown)
			{
				Cooldown = MonsterTypes[PickedMonster].Cost;
				DoCooldown();
			}
		}
		
		PickedMonster = -1;
		
		if(!bUseCostAsCooldown)
			CostPerSec = 0;
	}
}

defaultproperties
{
	PickedMonster=-1
	
	ArtifactID="MonsterSummon"
	Description="Summons a friendly monster of your choice."
	ItemName="Summoning Charm"
	PickupClass=Class'ArtifactPickupMonsterSummon'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.MonsterSummon'
	HudColor=(B=96,G=64,R=192)
	CostPerSec=0
	Cooldown=0
	bUseCostAsCooldown=False
	
	MonsterTypes(0)=(MonsterClass=class'SkaarjPack.SkaarjPupae',DisplayName="Skaarj Pupae",Cost=10);
	MonsterTypes(1)=(MonsterClass=class'SkaarjPack.Krall',DisplayName="Krall",Cost=25);
	MonsterTypes(2)=(MonsterClass=class'SkaarjPack.Brute',DisplayName="Brute",Cost=50);
	MonsterTypes(3)=(MonsterClass=class'SkaarjPack.Warlord',DisplayName="Warlord",Cost=75);
}
