class Ability_TurretSummon extends RPGAbility
	DependsOn(Artifact_SummonTurret);

struct TurretTypeStruct
{
	var int Level;
	var class<ASTurret> TurretClass;
	var int Cost;
    var int Cooldown;
};
var config array<TurretTypeStruct> TurretTypes;

var localized string TurretPreText, TurretPostText;

replication {
	reliable if(Role == ROLE_Authority)
		ClientReceiveTurretType;
}

simulated event PostNetBeginPlay() {
	Super.PostNetBeginPlay();
	
	if(Role < ROLE_Authority)
		TurretTypes.Length = 0;
}

function ServerRequestConfig() {
	local int i;

	Super.ServerRequestConfig();

	for(i = 0; i < TurretTypes.Length; i++)
		ClientReceiveTurretType(i, TurretTypes[i]);
}

simulated function ClientReceiveTurretType(int i, TurretTypeStruct T) {
    TurretTypes[i] = T;
}

function ModifyRPRI() {
	Super.ModifyRPRI();
	RPRI.MaxTurrets += (AbilityLevel - 1);
}

function ModifyPawn(Pawn Other) {
	local int i;
	local Artifact_SummonTurret.TurretTypeStruct ArtifactTurret;
	local Artifact_SummonTurret Artifact;
	local bool bSelect;
	
	Super.ModifyPawn(Other);
	
	Artifact = Artifact_SummonTurret(Other.FindInventoryType(class'Artifact_SummonTurret'));
	if(Artifact != None)
	{
		bSelect = (Artifact == Other.SelectedItem);
		Artifact.Destroy();
	}
	
	if(!bSelect)
		bSelect = (Other.SelectedItem == None);
	
	Artifact = Other.Spawn(class'Artifact_SummonTurret');
	if(Artifact != None)
	{
		Artifact.TurretTypes.Length = 0;
		for(i = 0; i < TurretTypes.Length; i++)
		{
			if(AbilityLevel >= TurretTypes[i].Level)
			{
				ArtifactTurret.TurretClass = TurretTypes[i].TurretClass;
				ArtifactTurret.Cost = TurretTypes[i].Cost;
				ArtifactTurret.Cooldown = TurretTypes[i].Cooldown;
				
				Artifact.TurretTypes[Artifact.TurretTypes.Length] = ArtifactTurret;
			}
		}
		Artifact.GiveTo(Other);
		
		if(bSelect)
			Other.SelectedItem = Artifact;
	}
}

/*
simulated function string DescriptionText() {
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
*/

defaultproperties {
	StatusIconClass=class'StatusIcon_Turrets'

	AbilityName="Turret Construction"
	Description="You are granted the Turret Construction artifact when you spawn.|Each level of this ability allows you to summon more turrets."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=3
	TurretTypes(0)=(Level=1,TurretClass=class'RPGSentinelTurret',Cost=50,Cooldown=30)
	TurretPreText=", you can construct the"
	TurretPostText="."
	Category=class'AbilityCategory_Engineer'
}
