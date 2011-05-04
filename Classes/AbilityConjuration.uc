class AbilityConjuration extends RPGAbility
	DependsOn(ArtifactMonsterSummon);

var config float MonsterSkill;

struct MonsterTypeStruct
{
	var int Level;
	var class<Monster> MonsterClass;
	var string DisplayName;
	var int Cost;
};
var config array<MonsterTypeStruct> MonsterTypes;

var ReplicatedArray MonsterTypesRepl;

var localized string MonsterPreText, MonsterPostText;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		MonsterTypesRepl;
}

simulated event PreBeginPlay()
{
	local int i;
	
	Super.PreBeginPlay();

	if(ShouldReplicateInfo())
	{
		MonsterTypesRepl = Spawn(class'ReplicatedArray', Owner);
		for(i = 0; i < MonsterTypes.Length; i++)
		{
			MonsterTypesRepl.ObjectArray[i] = MonsterTypes[i].MonsterClass;
			MonsterTypesRepl.IntArray[i] = MonsterTypes[i].Level;
			MonsterTypesRepl.IntArray[i + MonsterTypes.Length] = MonsterTypes[i].Cost;
			
			if(MonsterTypes[i].DisplayName == "")
				MonsterTypes[i].DisplayName = string(MonsterTypes[i].MonsterClass.Name);
			
			MonsterTypesRepl.StringArray[i] = MonsterTypes[i].DisplayName;
		}
		MonsterTypesRepl.Replicate();
		FinalSyncState++;
	}
}

simulated event PostNetReceive()
{
	local MonsterTypeStruct M;
	local int i;

	if(ShouldReceive() && MonsterTypesRepl != None)
	{
		MonsterTypes.Length = MonsterTypesRepl.ObjectArray.Length;
		for(i = 0; i < MonsterTypes.Length; i++)
		{
			M.MonsterClass = class<Monster>(MonsterTypesRepl.ObjectArray[i]);
			M.Level = MonsterTypesRepl.IntArray[i];
			M.Cost = MonsterTypesRepl.IntArray[i + MonsterTypes.Length];
			M.DisplayName = MonsterTypesRepl.StringArray[i];
			MonsterTypes[i] = M;
		}
		
		MonsterTypesRepl.SetOwner(Owner);
		MonsterTypesRepl.ServerDestroy();
		ClientSyncState++;
	}
	
	Super.PostNetReceive();
}

function ModifyPawn(Pawn Other)
{
	local int i;
	local ArtifactMonsterSummon.MonsterTypeStruct ArtifactMonster;
	local ArtifactMonsterSummon Artifact;
	local bool bSelect;
	
	Super.ModifyPawn(Other);
	
	Artifact = ArtifactMonsterSummon(Other.FindInventoryType(class'ArtifactMonsterSummon'));
	if(Artifact != None)
	{
		bSelect = (Artifact == Other.SelectedItem);
		Artifact.Destroy();
	}
	
	if(!bSelect)
		bSelect = (Other.SelectedItem == None);
	
	Artifact = Other.Spawn(class'ArtifactMonsterSummon');
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
}
