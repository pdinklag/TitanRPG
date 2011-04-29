class SelectionMenu_ConstructTurret extends RPGSelectionMenu;

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
			
			if(ArtifactTurretSummon(Artifact).TurretTypes[lstItems.List.Index].StaticMesh != None)
			{
				SpinnyItem.SetDrawType(DT_StaticMesh);
				SpinnyItem.SetStaticMesh(ArtifactTurretSummon(Artifact).TurretTypes[lstItems.List.Index].StaticMesh);
				
				if(ArtifactTurretSummon(Artifact).TurretTypes[lstItems.List.Index].DrawScale > 0)
					SpinnyItem.SetDrawScale(ArtifactTurretSummon(Artifact).TurretTypes[lstItems.List.Index].DrawScale);
				else
					SpinnyItem.SetDrawScale(SelectedTurret.default.DrawScale);
			}
			else
			{
				SpinnyItem.SetDrawType(DT_Mesh);
				SpinnyItem.LinkMesh(SelectedTurret.default.Mesh);
				SpinnyItem.SetDrawScale(SelectedTurret.default.DrawScale);
				
				SpinnyItem.Skins.Length = SelectedTurret.default.Skins.Length;
				for(i = 0; i < SelectedTurret.default.Skins.Length; i++)
					SpinnyItem.Skins[i] = SelectedTurret.default.Skins[i];
			}
		}
		else
		{
			SpinnyItem.SetDrawType(DT_Mesh);
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
	OKText="Construct"

	WindowTitle="Pick Turret to construct"
	
	ListTitle="Turrets"
	ListHint="Select a turret to construct"

	SpinnyItemOffset=(X=80,Y=-5,Z=-5)
	SpinnyItemRotation=(Pitch=-2048,Yaw=36864,Roll=0)
}
