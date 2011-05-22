class RPGMenu_Artifacts extends RPGMenu_TabPage
	DependsOn(RPGCharSettings);

var automated GUISectionBackground sbArtifactOrder, sbArtifact, sbGlobalSettings;
var automated GUIListBox lbArtifacts;
var automated GUIGFXButton btUp, btDown;
var automated GUIImage imIcon;
var automated GUIScrollTextBox lbDesc;
var automated moCheckbox chShowAlways, chNeverShow;

var automated moCheckBox chShowAll;

var bool bDirty, bOrderChanged;
var int SelectedOrderEntry;

var bool bIgnoreNextChange;

var localized string NotAvailableText, NotAvailableTitle, NotAvailableDesc;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	
	lbArtifacts.List.bDropSource = false;
	lbArtifacts.List.bDropTarget = false;
	lbArtifacts.List.bMultiSelect = false;

	lbArtifacts.OnClick = Clicked;
	lbArtifacts.OnKeyEvent = KeyEvent;
}

function InitMenu()
{
	local class<RPGArtifact> AClass;
	local bool bShowAll;
	local int i;

	lbArtifacts.List.bNotify = false;
	lbArtifacts.List.Clear();
	
	bShowAll = true;
	for(i = 0; i < RPGMenu.RPRI.ArtifactOrder.Length; i++)
	{
		bShowAll = bShowAll && RPGMenu.RPRI.ArtifactOrder[i].bShowAlways;

		AClass = RPGMenu.RPRI.ArtifactOrder[i].ArtifactClass;

		if(AClass != None)
			lbArtifacts.List.Add(AClass.default.ItemName, AClass);
		else
			lbArtifacts.List.Add(NotAvailableText @ RPGMenu.RPRI.ArtifactOrder[i].ArtifactID, None);
	}
	
	bIgnoreNextChange = true;
	chShowAll.Checked(bShowAll);
	bIgnoreNextChange = false;

	SelectArtifact();
}

function CloseMenu()
{
	local int i;
	local RPGCharSettings Settings;
	local RPGCharSettings.ArtifactOrderConfigStruct OrderConfigEntry;

	if(bDirty)
	{
		Settings = RPGMenu.RPRI.Interaction.CharSettings;
		Settings.ArtifactOrderConfig.Length = 0;
		
		for(i = 0; i < RPGMenu.RPRI.ArtifactOrder.Length; i++)
		{
			OrderConfigEntry.ArtifactID = RPGMenu.RPRI.ArtifactOrder[i].ArtifactID;
			OrderConfigEntry.bShowAlways = RPGMenu.RPRI.ArtifactOrder[i].bShowAlways;
			OrderConfigEntry.bNeverShow = RPGMenu.RPRI.ArtifactOrder[i].bNeverShow;
			
			Settings.ArtifactOrderConfig[Settings.ArtifactOrderConfig.Length] = OrderConfigEntry;
		}
		
		if(bOrderChanged && RPGMenu.RPRI != None)
		{
			RPGMenu.RPRI.ResendArtifactOrder();
			bOrderChanged = false;
		}
		
		bDirty = false;
	}
}

function SelectArtifact()
{
	local class<RPGArtifact> AClass;
	
	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something
	
	AClass = class<RPGArtifact>(lbArtifacts.List.GetObjectAtIndex(lbArtifacts.List.Index));
	if(AClass != None)
	{
		sbArtifact.Caption = AClass.default.ItemName;
		lbDesc.setContent(AClass.static.GetArtifactNameExtra());
		
		imIcon.Image = Texture(AClass.default.IconMaterial);
		imIcon.SetVisibility(true);
	}
	else
	{
		sbArtifact.Caption = NotAvailableTitle;
		lbDesc.setContent(NotAvailableDesc);
		imIcon.Image = None;
	}

	SelectedOrderEntry = lbArtifacts.List.Index;
	
	bIgnoreNextChange = true;
	chShowAlways.Checked(RPGMenu.RPRI.ArtifactOrder[SelectedOrderEntry].bShowAlways);
	chNeverShow.Checked(RPGMenu.RPRI.ArtifactOrder[SelectedOrderEntry].bNeverShow);
	bIgnoreNextChange = false;
}

function InternalOnChange(GUIComponent Sender)
{
	local int i;
	local bool bShowAll;
	
	if(bIgnoreNextChange)
		return;

	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something

	switch(Sender)
	{
		case chShowAlways:
			RPGMenu.RPRI.ArtifactOrder[SelectedOrderEntry].bShowAlways = chShowAlways.IsChecked();
			
			bShowAll = true;
			for(i = 0; i < RPGMenu.RPRI.ArtifactOrder.Length; i++)
				bShowAll = bShowAll && RPGMenu.RPRI.ArtifactOrder[i].bShowAlways;

			bIgnoreNextChange = true;
			chShowAll.Checked(bShowAll);
			bIgnoreNextChange = false;
			
			bDirty = true;
			break;
		
		case chNeverShow:
			RPGMenu.RPRI.ArtifactOrder[SelectedOrderEntry].bNeverShow = chNeverShow.IsChecked();
			bDirty = true;
			bOrderChanged = true; //will need to resend order data once applied
			break;
		
		case chShowAll:
			for(i = 0; i < RPGMenu.RPRI.ArtifactOrder.Length; i++)
				RPGMenu.RPRI.ArtifactOrder[i].bShowAlways = chShowAll.IsChecked();
			
			bIgnoreNextChange = true;
			chShowAlways.Checked(chShowAll.IsChecked());
			bIgnoreNextChange = false;
			
			bDirty = true;
			break;
	}
}

function bool KeyEvent(out byte Key, out byte State, float delta)
{
	if((Key == 38 || Key == 40) && State == 3) //up / down key released
	{
		SelectArtifact();
		return true;
	}
	else
    {
		return false;
	}
}

function bool Clicked(GUIComponent Sender)
{
	SelectArtifact();
	return true;
}

function SwapArtifacts(int i, int x)
{
	local RPGPlayerReplicationInfo.ArtifactOrderStruct OrderEntry;
	
	OrderEntry = RPGMenu.RPRI.ArtifactOrder[i];
	RPGMenu.RPRI.ArtifactOrder[i] = RPGMenu.RPRI.ArtifactOrder[x];
	RPGMenu.RPRI.ArtifactOrder[x] = OrderEntry;
	
	lbArtifacts.List.Swap(i, x);
	lbArtifacts.List.SetIndex(x);
	
	SelectedOrderEntry = lbArtifacts.List.Index;
	bDirty = true;
	bOrderChanged = true;
}

function bool ChangePriority(GUIComponent Sender)
{
	if(lbArtifacts.List.ItemCount > 1)
	{
		if(Sender == btUp && lbArtifacts.List.Index > 0)
			SwapArtifacts(lbArtifacts.List.Index, lbArtifacts.List.Index - 1);
		else if(Sender == btDown && lbArtifacts.List.Index < lbArtifacts.List.ItemCount - 1)
			SwapArtifacts(lbArtifacts.List.Index, lbArtifacts.List.Index + 1);
	}
	return true;
}


defaultproperties
{
	NotAvailableText="N/A:"
	NotAvailableTitle="N/A"
	NotAvailableDesc="This artifact is not available on this server."

	Begin Object Class=AltSectionBackground Name=sbArtifactOrder_
		Caption="Artifact order"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.454518
		WinHeight=0.929236
		WinLeft=0.000085
		WinTop=0.013226
		OnPreDraw=sbArtifactOrder_.InternalPreDraw
	End Object
	sbArtifactOrder=GUISectionBackground'sbArtifactOrder_'
	
	Begin Object Class=AltSectionBackground Name=sbArtifact_
		Caption=""
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.534992
		WinHeight=0.461826
		WinLeft=0.459614
		WinTop=0.013226
		OnPreDraw=sbArtifact_.InternalPreDraw
	End Object
	sbArtifact=GUISectionBackground'sbArtifact_'
	
	Begin Object Class=AltSectionBackground Name=sbGlobalSettings_
		Caption="Global Settings"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.534992
		WinHeight=0.451364
		WinLeft=0.459614
		WinTop=0.490386
		OnPreDraw=sbGlobalSettings_.InternalPreDraw
	End Object
	sbGlobalSettings=GUISectionBackground'sbGlobalSettings_'

	Begin Object Class=GUIListBox Name=WeaponPrefWeapList
		WinWidth=0.406740
		WinHeight=0.740111
		WinLeft=0.026297
		WinTop=0.105213
		bVisibleWhenEmpty=true
		Hint="Select order for artifacts."
		RenderWeight=0.51
		StyleName="NoBackground"
		TabOrder=1
	End Object
	lbArtifacts=WeaponPrefWeapList
	
	Begin Object Class=GUIGFXButton Name=WeaponPrefWeapUp
		Hint="Move artifact up in the order."
		WinWidth=0.041017
		WinHeight=0.056701
		WinLeft=0.193755
		WinTop=0.883934
		OnClick=ChangePriority
		OnClickSound=CS_Up
		RenderWeight=0.51
		TabOrder=2
		StyleName="AltComboButton"
		bAcceptsInput=True
		Position=ICP_Scaled
		bNeverFocus=true
		bCaptureMouse=true
		bRepeatClick=True
		ImageIndex=6
	End Object
	btUp=WeaponPrefWeapUp

	Begin Object Class=GUIGFXButton Name=WeaponPrefWeapDown
		Hint="Move artifact down in the order."
		WinWidth=0.041017
		WinHeight=0.056701
		WinLeft=0.234758
		WinTop=0.883934
		RenderWeight=0.51
		OnClick=ChangePriority
		OnClickSound=CS_Down
		TabOrder=3
		StyleName="ComboButton"
		bAcceptsInput=True
		Position=ICP_Scaled
		bNeverFocus=true
		bCaptureMouse=true
		bRepeatClick=True
		ImageIndex=7
	End Object
	btDown=WeaponPrefWeapDown
	
	Begin Object Class=GUIScrollTextBox Name=WeaponDescription
		WinWidth=0.388324
		WinHeight=0.120566
		WinLeft=0.580170
		WinTop=0.114915
		CharDelay=0.001250
		EOLDelay=0.001250
		bNeverFocus=true
		bAcceptsInput=false
		bVisibleWhenEmpty=True
		RenderWeight=0.51
		TabOrder=4
		FontScale=FNS_Small
        StyleName="NoBackground"
	End Object
	lbDesc=WeaponDescription
	
	Begin Object class=moCheckBox Name=ShowAlwaysCheckbox
		WinWidth=0.242672
		WinHeight=0.042105
		WinLeft=0.719278
		WinTop=0.255714
		Caption="Show always"
		Hint="If activated, this artifact is always shown even if you don't have it."
		CaptionWidth=0.9
		bSquare=True
		ComponentJustification=TXTA_Right
		LabelJustification=TXTA_Left
		ComponentWidth=-1
		RenderWeight=1.01
		TabOrder=5
		OnChange=RPGMenu_Artifacts.InternalOnChange
	End Object
	chShowAlways=ShowAlwaysCheckbox

	Begin Object class=moCheckBox Name=NeverShowCheckbox
		WinWidth=0.242672
		WinHeight=0.044444
		WinLeft=0.719278
		WinTop=0.315432
		Caption="Never show"
		Hint="If activated, this artifact will never be displayed and cannot be selected (overrides the Show Always option)."
		CaptionWidth=0.9
		bSquare=True
		ComponentJustification=TXTA_Right
		LabelJustification=TXTA_Left
		ComponentWidth=-1
		RenderWeight=1.01
		TabOrder=6
		OnChange=RPGMenu_Artifacts.InternalOnChange
	End Object
	chNeverShow=NeverShowCheckbox
	
	Begin Object class=GUIImage Name=GameCrossHairImage
		WinWidth=0.079098
		WinHeight=0.120794
		WinLeft=0.487776
		WinTop=0.114236
		X1=0
		Y1=0
		X2=64
		Y2=64
		ImageColor=(R=255,G=255,B=255,A=255)
		ImageRenderStyle=MSTY_Alpha
		ImageStyle=ISTY_Scaled
		ImageAlign=IMGA_TopLeft
        RenderWeight=0.55
	End Object
	imIcon=GameCrossHairImage
	
	Begin Object class=moCheckBox Name=ShowAllChk
		WinWidth=0.480585
		WinHeight=0.044444
		WinLeft=0.482611
		WinTop=0.595503
		Caption="Always show all artifacts"
		Hint="Quickly toggles Show always for all artifacts."
		CaptionWidth=0.9
		bSquare=True
		ComponentJustification=TXTA_Right
		LabelJustification=TXTA_Left
		ComponentWidth=-1
		RenderWeight=1.01
		TabOrder=7
		OnChange=RPGMenu_Artifacts.InternalOnChange
	End Object
	chShowAll=ShowAllChk
	
	WinHeight=0.700000
}