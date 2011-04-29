/*
	Base class for selection menus, used for e.g.:
	- Summoning Charm
	- Turret Builder
	- Magic Weapon Maker X
*/
class RPGSelectionMenu extends FloatingWindow
	abstract
	config(TitanRPGSettings);

var Pawn Instigator;
var RPGPlayerReplicationInfo RPRI;
var RPGArtifact Artifact;

var automated GUISectionBackground sbList, sbPreview;
var automated GUIListBox lstItems;
var automated GUIButton btOK;

var automated moCheckBox chFavorite;

var SpinnyWeap SpinnyItem; // MUST be set to null when you leave the window
var vector SpinnyItemOffset;
var rotator SpinnyItemRotation;
var bool bFixedRotation;

var localized string WindowTitle;
var localized string ListTitle, ListHint;
var localized string OKText;

var config int Favorite;

static function RPGSelectionMenu ShowFor(RPGArtifact A)
{
	local RPGSelectionMenu Menu;
	local GUIController GUIController;
	
	GUIController = GUIController(PlayerController(A.Instigator.Controller).Player.GUIController);
	if(GUIController != None)
	{
		GUIController.OpenMenu(string(default.class));
		
		Menu = RPGSelectionMenu(GUIController.TopPage());
		if(Menu != None)
		{
			Menu.InitFor(A);
			return Menu;
		}
	}
	return None;
}

function int DefaultItem()
{
	if(Favorite >= 0 && Favorite < GetNumItems())
		return Favorite;
	else
		return GetDefaultItemIndex();
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	btOK.Caption = OKText;
	
	t_WindowTitle.SetCaption(WindowTitle);
	
	sbList.Caption = ListTitle;
	lstItems.Hint = ListHint;
}

function InitFor(RPGArtifact A)
{
	local int i;

	Artifact = A;
	Instigator = A.Instigator;
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);

	//Setup and fill list
	lstItems.List.bNotify = false;
	lstItems.List.Clear();
	
	for(i = 0; i < GetNumItems(); i++)
		lstItems.List.Add(GetItem(i));

	//Spawn spinny actor
	if(SpinnyItem == None)
		SpinnyItem = PlayerOwner().Spawn(class'XInterface.SpinnyWeap');
	
	SpinnyItem.SetDrawType(DT_Mesh);
	
	SpinnyItem.bHidden = true;
	SpinnyItem.bPlayCrouches = false;
    SpinnyItem.bPlayRandomAnims = false;

	// Start with first item on list selected
	lstItems.List.SetIndex(Max(0, DefaultItem()));
	lstItems.List.bNotify = true;

	chFavorite.bIgnoreChange = true;
	chFavorite.Checked(lstItems.List.Index == Favorite);
	chFavorite.bIgnoreChange = false;
	
	SelectItem();
	
	SetTimer(0.05f, true);
}

function Timer()
{
	if(
		Artifact == None ||
		Artifact.Instigator != Instigator ||
		Instigator == None ||
		Instigator.Health <= 0
	)
	{
		Controller.CloseMenu(false);
	}
}

event Closed(GUIComponent Sender, bool bCancelled)
{
	KillTimer();
	Super.Closed(Sender, bCancelled);
}

event Free()
{
	Instigator = None;
	Artifact = None;

	if(SpinnyItem != None)
	{
		SpinnyItem.Destroy();
		SpinnyItem = None;
	}

	Super.Free();
}

function InternalOnChange(GUIComponent Sender)
{
	if(Sender == lstItems)
	{
		chFavorite.bIgnoreChange = true;
		chFavorite.Checked(lstItems.List.Index == Favorite);
		chFavorite.bIgnoreChange = false;
		
		SelectItem();
	}
}

static function rotator GetRelativeRotation(rotator Rotation, rotator BaseRotation)
{
	local vector X, Y, Z;
	
	GetAxes(Rotation, X, Y, Z);
	return OrthoRotation(X >> BaseRotation, Y >> BaseRotation, Z >> BaseRotation);
}

function InternalDraw(Canvas Canvas)
{
	local vector CamPos, X, Y, Z, WX, WY, WZ;
	local rotator CamRot;

	if(
		SpinnyItem == None ||
		(SpinnyItem.DrawType == DT_Mesh && SpinnyItem.Mesh == None) ||
		(SpinnyItem.DrawType == DT_StaticMesh && SpinnyItem.StaticMesh == None)
	)
	{
		return;
	}

	Canvas.GetCameraLocation(CamPos, CamRot);
	GetAxes(CamRot, X, Y, Z);
	
	if(bFixedRotation)
	{
		GetAxes(CamRot, X, Y, Z);
		SpinnyItem.SetLocation(CamPos + SpinnyItemOffset.X * X + SpinnyItemOffset.Y * Y + SpinnyItemOffset.Z * Z);
		SpinnyItem.SetRotation(GetRelativeRotation(SpinnyItemRotation, CamRot));
	}
	else
	{
		if(SpinnyItem.DrawType == DT_Mesh)
		{
			GetAxes(SpinnyItem.Rotation, WX, WY, WZ);
			SpinnyItem.SetLocation(CamPos + SpinnyItemOffset.X * X + SpinnyItemOffset.Y * Y + SpinnyItemOffset.Z * Z + 30 * WX);
		}
		else
		{
			SpinnyItem.SetLocation(CamPos + SpinnyItemOffset.X * X + SpinnyItemOffset.Y * Y + SpinnyItemOffset.Z * Z);
		}
	}

	SpinnyItem.bHidden = false;
	Canvas.DrawActorClipped(
		SpinnyItem,
		false,
		sbPreview.ClientBounds[0],
		sbPreview.ClientBounds[1],
		sbPreview.ClientBounds[2] - sbPreview.ClientBounds[0],
		sbPreview.ClientBounds[3] - sbPreview.ClientBounds[1],
		true,
		90.0
	);
		
	SpinnyItem.bHidden = true;
}

function bool InternalOnKeyEvent(out byte iKey, out byte State, float Delta)
{
	local string Temp;
	
	if(State == 1)
	{		
		Temp = PlayerOwner().ConsoleCommand("KEYNAME" @ iKey);
		
		//default bindings
		if(
			RPRI != None &&
			RPRI.Interaction != None &&
			RPRI.Interaction.bDefaultArtifactBindings &&
			Temp ~= "U"
		)
		{
			OKClicked(None);
			return true;
		}
		
		Temp = PlayerOwner().ConsoleCommand("KEYBINDING" @ Temp);
		
		//ActivateItem equals a click on OK
		if(Temp ~= "ActivateItem" || Temp ~= "InventoryActivate")
		{
			OKClicked(None);
			return true;
		}
	}
	return false;
}

function ChangeFav(GUIComponent Sender)
{
	if(chFavorite.IsChecked())
		Favorite = lstItems.List.Index;
	else
		Favorite = -1;
	
	SaveConfig();
}

//abstract - override in subclasses
function bool OKClicked(GUIComponent Sender)
{
	Controller.CloseMenu(false);
	return true;
}

function int GetNumItems(); //returns the amount of selectable items
function string GetItem(int i); //returns the display name of the item at index i

function int GetDefaultItemIndex(); //returns the index of the item that will be selected by default

function SelectItem(); //called when an item gets selected

defaultproperties
{
	Favorite=-1

	Begin Object class=AltSectionBackground Name=PreviewBG
		WinWidth=0.503124
		WinHeight=0.765326
		WinLeft=0.474349
		WinTop=0.088034
        Caption="Preview"
	End Object
	sbPreview=GUISectionBackground'PreviewBG'
	
	Begin Object class=AltSectionBackground Name=ListBG
		WinWidth=0.432088
		WinHeight=0.765326
		WinLeft=0.032087
		WinTop=0.088034
        Caption="Items"
	End Object
	sbList=GUISectionBackground'ListBG'
	
	Begin Object Class=GUIButton Name=OKButton
		Caption="OK"
		WinWidth=0.506902
		WinHeight=0.087200
		WinLeft=0.469923
		WinTop=0.860348
		OnClick=OKClicked
		OnKeyEvent=OKButton.InternalOnKeyEvent
	End Object
	btOK=GUIButton'OKButton'
	
	Begin Object Class=moCheckBox Name=FavButton
		Caption="Favorite"
		Hint="If checked, the selected item is your favorite item. It will be automatically selected whenever you open this menu."
		WinWidth=0.213021
		WinHeight=0.050000
		WinLeft=0.245833
		WinTop=0.877709
		OnChange=ChangeFav
	End Object
	chFavorite=moCheckBox'FavButton'
	
	Begin Object Class=GUIListBox Name=ItemsList
		WinWidth=0.390421
		WinHeight=0.554389
		WinLeft=0.052921
		WinTop=0.192202
		bVisibleWhenEmpty=true
		OnChange=InternalOnChange
		RenderWeight=0.51
		StyleName="NoBackground"
		TabOrder=1
	End Object
	lstItems=ItemsList

	bResizeWidthAllowed=False
	bResizeHeightAllowed=False
	bMoveAllowed=False
	bPersistent=True
    bAllowedAsLast=True
	
	OnKeyEvent=InternalOnKeyEvent
	OnRendered=InternalDraw
	
	WinLeft=0.20
	WinTop=0.20
	WinWidth=0.60
	WinHeight=0.60
	
	SpinnyItemOffset=(X=80,Y=0,Z=0)
	SpinnyItemRotation=(Pitch=0,Yaw=36864,Roll=0)
	bFixedRotation=True
	
	OKText="OK"
}

