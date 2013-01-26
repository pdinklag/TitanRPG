class Ability_TotemSummon extends RPGAbility
	DependsOn(Artifact_SummonTotem);

struct TotemTypeStruct
{
	var int Level;
	var class<RPGTotem> TotemClass;
	var int Cost;
    var int Cooldown;
};
var config array<TotemTypeStruct> TotemTypes;

var localized string TotemPreText, TotemPostText;

replication {
	reliable if(Role == ROLE_Authority)
		ClientReceiveTotemType;
}

simulated event PostNetBeginPlay() {
	Super.PostNetBeginPlay();
	
	if(Role < ROLE_Authority)
		TotemTypes.Length = 0;
}

function ServerRequestConfig() {
	local int i;

	Super.ServerRequestConfig();

	for(i = 0; i < TotemTypes.Length; i++)
		ClientReceiveTotemType(i, TotemTypes[i]);
}

simulated function ClientReceiveTotemType(int i, TotemTypeStruct T) {
    TotemTypes[i] = T;
}

function ModifyRPRI() {
	Super.ModifyRPRI();
	RPRI.MaxTotems += (AbilityLevel - 1);
}

function ModifyPawn(Pawn Other) {
	local int i;
	local Artifact_SummonTotem.TotemTypeStruct ArtifactTotem;
	local Artifact_SummonTotem Artifact;
	local bool bSelect;
	
	Super.ModifyPawn(Other);
	
	Artifact = Artifact_SummonTotem(Other.FindInventoryType(class'Artifact_SummonTotem'));
	if(Artifact != None)
	{
		bSelect = (Artifact == Other.SelectedItem);
		Artifact.Destroy();
	}
	
	if(!bSelect)
		bSelect = (Other.SelectedItem == None);
	
	Artifact = Other.Spawn(class'Artifact_SummonTotem');
	if(Artifact != None)
	{
		Artifact.TotemTypes.Length = 0;
		for(i = 0; i < TotemTypes.Length; i++)
		{
			if(AbilityLevel >= TotemTypes[i].Level)
			{
				ArtifactTotem.TotemClass = TotemTypes[i].TotemClass;
				ArtifactTotem.Cost = TotemTypes[i].Cost;
				ArtifactTotem.Cooldown = TotemTypes[i].Cooldown;
				
				Artifact.TotemTypes[Artifact.TotemTypes.Length] = ArtifactTotem;
			}
		}
		Artifact.GiveTo(Other);
		
		if(bSelect)
			Other.SelectedItem = Artifact;
	}
}

simulated function string DescriptionText() {
	local int lv, x;
	local string text;
	local array<string> list;
	
	text = Super.DescriptionText();
	
 	for(lv = 1; lv <= MaxLevel; lv++)
	{
		list.Remove(0, list.Length);
		for(x = 0; x < TotemTypes.Length; x++)
		{
			if(TotemTypes[x].TotemClass != None && TotemTypes[x].Level == lv)
				list[list.Length] = TotemTypes[x].TotemClass.default.VehicleNameString;
		}
		
		if(list.Length > 0)
		{
			text $= "|" $ AtLevelText @ string(lv) $ TotemPreText;
			for(x = 0; x < list.Length; x++)
			{
				text @= list[x];
				
				if(x + 2 < list.Length)
					text $= ",";
				else if(x + 1 < list.Length)
					text @= AndText;
			}
			text $= TotemPostText;
		}
	}
	return text;
}

defaultproperties {
	StatusIconClass=class'StatusIcon_Totems'

	AbilityName="Totem Construction"
	Description="You are granted the Totem Construction artifact when you spawn.|Each level of this ability allows you to summon more totems."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=3
	TotemTypes(0)=(Level=1,TotemClass=class'Totem_Heal',Cost=50,Cooldown=30)
	TotemTypes(1)=(Level=2,TotemClass=class'Totem_Lightning',Cost=50,Cooldown=30)
	TotemPreText=", you can construct the"
	TotemPostText="."
	Category=class'AbilityCategory_Engineer'
}
