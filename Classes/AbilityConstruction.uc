class AbilityConstruction extends RPGAbility
	DependsOn(Artifact_TurretSummon);

struct TurretTypeStruct
{
	var int Level;
	var class<Vehicle> TurretClass;
	var int Cost;
	
	//Preview
	var StaticMesh StaticMesh;
	var float DrawScale;
};
var config array<TurretTypeStruct> TurretTypes;

var localized string TurretPreText, TurretPostText;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReceiveTurretType;
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	
	if(Role < ROLE_Authority)
		TurretTypes.Length = 0;
}

function ServerRequestConfig()
{
	local int i;

	Super.ServerRequestConfig();

	for(i = 0; i < TurretTypes.Length; i++)
		ClientReceiveTurretType(i, TurretTypes[i]);
}

simulated function ClientReceiveTurretType(int i, TurretTypeStruct T)
{
	TurretTypes[i] = T;
}

function ModifyPawn(Pawn Other)
{
	local int i;
	local Artifact_TurretSummon.TurretTypeStruct ArtifactTurret;
	local Artifact_TurretSummon Artifact;
	local bool bSelect;
	
	Super.ModifyPawn(Other);
	
	Artifact = Artifact_TurretSummon(Other.FindInventoryType(class'Artifact_TurretSummon'));
	if(Artifact != None)
	{
		bSelect = (Artifact == Other.SelectedItem);
		Artifact.Destroy();
	}
	
	if(!bSelect)
		bSelect = (Other.SelectedItem == None);
	
	Artifact = Other.Spawn(class'Artifact_TurretSummon');
	if(Artifact != None)
	{
		Artifact.TurretTypes.Length = 0;
		for(i = 0; i < TurretTypes.Length; i++)
		{
			if(AbilityLevel >= TurretTypes[i].Level)
			{
				ArtifactTurret.TurretClass = TurretTypes[i].TurretClass;
				ArtifactTurret.Cost = TurretTypes[i].Cost;
				ArtifactTurret.StaticMesh = TurretTypes[i].StaticMesh;
				ArtifactTurret.DrawScale = TurretTypes[i].DrawScale;
				
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
	StatusIconClass=class'StatusIcon_Turrets'

	AbilityName="Construction"
	Description="You are granted the Turret Construction artifact when you spawn.|Each level of this ability allows you to summon more powerful turrets."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=3
	TurretTypes(0)=(Level=1,TurretClass=class'UT2k4Assault.ASVehicle_Sentinel_Floor',Cost=100,StaticMesh=StaticMesh'AS_Weapons_SM.FloorTurretStaticEditor',DrawScale=0.125)
	TurretTypes(1)=(Level=2,TurretClass=class'UT2k4AssaultFull.ASTurret_BallTurret',Cost=125,StaticMesh=StaticMesh'<? echo($packageName); ?>.TurretPreview.BallTurret',DrawScale=1.00)
	TurretTypes(2)=(Level=3,TurretClass=class'UT2k4AssaultFull.ASTurret_LinkTurret',Cost=150,StaticMesh=StaticMesh'<? echo($packageName); ?>.TurretPreview.LinkTurret',DrawScale=0.0625)
	TurretPreText=", you can construct the"
	TurretPostText="."
	Category=class'AbilityCategory_Engineer'
}
