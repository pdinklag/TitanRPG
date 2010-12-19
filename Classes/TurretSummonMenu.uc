class TurretSummonMenu extends RPGSelectionMenu;

var localized string WindowTitle;
var localized string ListTitle, ListHint;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	
	t_WindowTitle.SetCaption(WindowTitle);
	
	sbList.Caption = ListTitle;
	lstItems.Hint = ListHint;
}

function int GetNumItems()
{
	return ArtifactTurretSummon(Artifact).TurretTypes.Length;
}

function string GetItem(int i)
{
	return
		ArtifactTurretSummon(Artifact).TurretTypes[i].TurretClass.default.VehicleNameString @
		"(" $ ArtifactTurretSummon(Artifact).TurretTypes[i].Cost $ ")";
}

function int GetDefaultItemIndex()
{
	return ArtifactTurretSummon(Artifact).PickBest();
}

function SelectItem()
{
	local int i;
	local int Cost;
	local class<Vehicle> SelectedTurret;

	if(SpinnyItem != None)
	{
		if(lstItems.List.Index >= 0)
		{
			SelectedTurret = ArtifactTurretSummon(Artifact).TurretTypes[lstItems.List.Index].TurretClass;
			SpinnyItem.LinkMesh(SelectedTurret.default.Mesh);
			
			SpinnyItem.Skins.Length = SelectedTurret.default.Skins.Length;
			for(i = 0; i < SelectedTurret.default.Skins.Length; i++)
				SpinnyItem.Skins[i] = SelectedTurret.default.Skins[i];
		}
		else
		{
			SpinnyItem.LinkMesh(None);
		}
	}
	
	Cost = ArtifactTurretSummon(Artifact).TurretTypes[lstItems.List.Index].Cost;
	if(Cost > PlayerOwner().Adrenaline)
		btOK.MenuState = MSAT_Disabled;
	else
		btOK.MenuState = MSAT_Blurry;
}

function bool OKClicked(GUIComponent Sender)
{
	ArtifactTurretSummon(Artifact).ServerPickTurret(lstItems.List.Index);
	return Super.OKClicked(Sender);
}

defaultproperties
{
	WindowTitle="Pick Turret to construct"
	
	ListTitle="Turrets"
	ListHint="Select a turret to construct"

	SpinnyItemOffset=(X=80,Y=0,Z=0)
	SpinnyItemRotation=(Pitch=0,Yaw=36864,Roll=0)
}
