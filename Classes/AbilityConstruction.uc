class AbilityConstruction extends RPGAbility
	DependsOn(ArtifactTurretSummon);

struct TurretTypeStruct
{
	var int Level;
	var class<Vehicle> TurretClass;
	var int Cost;
};
var config array<TurretTypeStruct> TurretTypes;

var ReplicatedArray TurretTypesRepl;

var localized string TurretPreText, TurretPostText;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		TurretTypesRepl;
}

simulated event PreBeginPlay()
{
	local int i;
	
	Super.PreBeginPlay();

	if(ShouldReplicateInfo())
	{
		TurretTypesRepl = Spawn(class'ReplicatedArray', Owner);
		for(i = 0; i < TurretTypes.Length; i++)
		{
			TurretTypesRepl.ObjectArray[i] = TurretTypes[i].TurretClass;
			TurretTypesRepl.IntArray[i] = TurretTypes[i].Level;
			TurretTypesRepl.IntArray[i + TurretTypes.Length] = TurretTypes[i].Cost;
		}
		TurretTypesRepl.Replicate();
	}
}

simulated event PostNetReceive()
{
	local TurretTypeStruct T;
	local int i;
	
	Super.PostNetReceive();

	if(Role < ROLE_Authority && TurretTypesRepl != None)
	{
		TurretTypes.Length = TurretTypesRepl.ObjectArray.Length;
		for(i = 0; i < TurretTypes.Length; i++)
		{
			T.TurretClass = class<Vehicle>(TurretTypesRepl.ObjectArray[i]);
			T.Level = TurretTypesRepl.IntArray[i];
			T.Cost = TurretTypesRepl.IntArray[i + TurretTypes.Length];
			TurretTypes[i] = T;
		}
		
		TurretTypesRepl.SetOwner(Owner);
		TurretTypesRepl.ServerDestroy();
	}
}

function ModifyPawn(Pawn Other)
{
	local int i;
	local ArtifactTurretSummon.TurretTypeStruct ArtifactTurret;
	local ArtifactTurretSummon Artifact;
	local bool bSelect;
	
	Super.ModifyPawn(Other);
	
	Artifact = ArtifactTurretSummon(Other.FindInventoryType(class'ArtifactTurretSummon'));
	if(Artifact != None)
	{
		bSelect = (Artifact == Other.SelectedItem);
		Artifact.Destroy();
	}
	
	if(!bSelect)
		bSelect = (Other.SelectedItem == None);
	
	Artifact = Other.Spawn(class'ArtifactTurretSummon');
	if(Artifact != None)
	{
		Artifact.TurretTypes.Length = 0;
		for(i = 0; i < TurretTypes.Length; i++)
		{
			if(AbilityLevel >= TurretTypes[i].Level)
			{
				ArtifactTurret.TurretClass = TurretTypes[i].TurretClass;
				ArtifactTurret.Cost = TurretTypes[i].Cost;
				
				Artifact.TurretTypes[Artifact.TurretTypes.Length] = ArtifactTurret;
			}
		}
		Artifact.GiveTo(Other);
		
		if(bSelect)
			Other.SelectedItem = Artifact;
	}
}

function ModifyTurret(Vehicle T, Pawn Other)
{
	//TODO
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
		for(x = 0; x < TurretTypes.Length; x++)
		{
			if(TurretTypes[x].TurretClass != None && TurretTypes[x].Level == lv)
				list[list.Length] = TurretTypes[x].TurretClass.default.VehicleNameString;
		}
		
		if(list.Length > 0)
		{
			text $= "|" $ AtLevelText @ string(lv) $ TurretPreText;
			for(x = 0; x < list.Length; x++)
			{
				text @= list[x];
				
				if(x + 2 < list.Length)
					text $= ",";
				else if(x + 1 < list.Length)
					text @= AndText;
			}
			text $= TurretPostText;
		}
	}
	return text;
}

defaultproperties
{
	AbilityName="Construction"
	Description="You are granted the Turret Construction artifact when you spawn.|Each level of this ability allows you to summon more powerful turrets."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=3
	TurretTypes(0)=(Level=1,TurretClass=class'UT2k4AssaultFull.ASTurret_BallTurret',Cost=25)
	TurretTypes(1)=(Level=2,TurretClass=class'UT2k4Assault.ASTurret_Minigun',Cost=25)
	TurretTypes(2)=(Level=2,TurretClass=class'UT2k4Assault.ASVehicle_Sentinel_Floor',Cost=50)
	TurretTypes(3)=(Level=3,TurretClass=class'UT2k4AssaultFull.ASTurret_LinkTurret',Cost=75)

	TurretPreText=", you can construct the"
	TurretPostText="."
}
