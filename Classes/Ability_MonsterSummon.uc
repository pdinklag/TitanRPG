class Ability_MonsterSummon extends RPGAbility
	DependsOn(Artifact_SummonMonster);

var config float MonsterSkill;

struct MonsterTypeStruct
{
	var int Level;
	var class<Monster> MonsterClass;
	var string DisplayName;
	var int Cost;
	var int Cooldown;
};
var config array<MonsterTypeStruct> MonsterTypes;

var localized string MonsterPreText, MonsterPostText;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReceiveMonsterType;
}

simulated function ClientReceived()
{
	Super.ClientReceived();
	MonsterTypes.Length = 0;
}

function ServerRequestConfig()
{
	local int i;

	Super.ServerRequestConfig();

	for(i = 0; i < MonsterTypes.Length; i++)
		ClientReceiveMonsterType(i, MonsterTypes[i]);
}

simulated function ClientReceiveMonsterType(int i, MonsterTypeStruct M)
{
	MonsterTypes[i] = M;
}

function ModifyPawn(Pawn Other)
{
	local int i;
	local Artifact_SummonMonster.MonsterTypeStruct ArtifactMonster;
	local Artifact_SummonMonster Artifact;
	local bool bSelect;
	
	Super.ModifyPawn(Other);
	
	Artifact = Artifact_SummonMonster(Other.FindInventoryType(class'Artifact_SummonMonster'));
	if(Artifact != None)
	{
		bSelect = (Artifact == Other.SelectedItem);
		Artifact.Destroy();
	}
	
	if(!bSelect)
		bSelect = (Other.SelectedItem == None);
	
	Artifact = Other.Spawn(class'Artifact_SummonMonster');
	if(Artifact != None)
	{
		Artifact.bCanBeTossed = false;
		Artifact.MonsterTypes.Length = 0;
		for(i = 0; i < MonsterTypes.Length; i++)
		{
			if(AbilityLevel >= MonsterTypes[i].Level)
			{
				ArtifactMonster.MonsterClass = MonsterTypes[i].MonsterClass;
				ArtifactMonster.DisplayName = MonsterTypes[i].DisplayName;
				ArtifactMonster.Cost = MonsterTypes[i].Cost;
				ArtifactMonster.Cooldown = MonsterTypes[i].Cooldown;
				
				Artifact.MonsterTypes[Artifact.MonsterTypes.Length] = ArtifactMonster;
			}
		}
		Artifact.GiveTo(Other);
		
		if(bSelect)
			Other.SelectedItem = Artifact;
	}
}

function ModifyMonster(Monster M, Pawn Master)
{
	MonsterController(M.Controller).InitializeSkill(MonsterSkill);
}

simulated function string DescriptionText()
{
	local int lv, x;
	local string text;
	local array<string> list;
	
	text = Super.DescriptionText();
	
	for(lv = 1; lv <= MaxLevel; lv++)
	{
		list.Remove(0, list.Length);
		for(x = 0; x < MonsterTypes.Length; x++)
		{
			if(MonsterTypes[x].MonsterClass != None && MonsterTypes[x].Level == lv)
				list[list.Length] = MonsterTypes[x].DisplayName;
		}
		
		if(list.Length > 0)
		{
			text $= "|" $ AtLevelText @ string(lv) $ MonsterPreText;
			for(x = 0; x < list.Length; x++)
			{
				text @= list[x];
				
				if(x + 2 < list.Length)
					text $= ",";
				else if(x + 1 < list.Length)
					text @= AndText;
			}
			text $= MonsterPostText;
		}
	}
	return text;
}

defaultproperties
{
	StatusIconClass=class'StatusIcon_Monsters'

	MonsterSkill=2
	AbilityName="Conjuration"
	Description="You are granted the Monster Summon artifact when you spawn.|Each level of this ability allows you to summon more powerful monsters."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=3
	MonsterTypes(0)=(Level=1,MonsterClass=Class'SkaarjPack.SkaarjPupae',DisplayName="Skaarj Pupae",Cost=10)
	MonsterTypes(1)=(Level=1,MonsterClass=Class'SkaarjPack.Razorfly',DisplayName="Razorfly",Cost=10)
	MonsterTypes(2)=(Level=2,MonsterClass=Class'SkaarjPack.Krall',DisplayName="Krall",Cost=25)
	MonsterTypes(3)=(Level=2,MonsterClass=Class'SkaarjPack.Manta',DisplayName="Manta",Cost=25)
	MonsterTypes(4)=(Level=3,MonsterClass=Class'SkaarjPack.Brute',DisplayName="Brute",Cost=50)
	MonsterTypes(5)=(Level=3,MonsterClass=Class'SkaarjPack.Gasbag',DisplayName="Gasbag",Cost=50)
	MonsterTypes(6)=(Level=3,MonsterClass=Class'SkaarjPack.Warlord',DisplayName="Warlord",Cost=75)
	MonsterPreText=", you can summon the"
	MonsterPostText="."
	Category=class'AbilityCategory_Monsters'
}
