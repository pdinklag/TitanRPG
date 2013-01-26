class RPGMenu extends FloatingWindow;

var RPGPlayerReplicationInfo RPRI;

var array<GUITabItem> Panels;

var automated GUITabControl Tabs;

var bool bStats; //set by RPRI

var localized string WindowTitle;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;
	
	MyController.RegisterStyle(class'STY_RPGListSection');
	
	Super.InitComponent(MyController, MyOwner);

	if(bStats)
		Panels[1].ClassName = "RPGMenu_AbilitiesMaster";
    
	for(i = 0; i < Panels.Length; i++)
	{
		//Prepend package name to class name
		Panels[i].ClassName = class'MutTitanRPG'.default.PackageName $ "." $ Panels[i].ClassName;
		
		Log("Adding tab:" @ Panels[i].ClassName, 'DEBUG');
		Tabs.AddTabItem(Panels[i]);
	}
	
	t_WindowTitle.SetCaption(WindowTitle);
	t_WindowTitle.DockedTabs = Tabs;
}

function InitFor(RPGPlayerReplicationInfo Whom)
{
	local int i;

	RPRI = Whom;
	
	if(RPRI.Level.NetMode == NM_Standalone)
		RPRI.Level.Game.SetPause(true, PlayerController(RPRI.Controller));	
	
	RPRI.Menu = Self;
	
	for(i = 0; i < Tabs.TabStack.Length; i++)
	{
		RPGMenu_TabPage(Tabs.TabStack[i].MyPanel).RPGMenu = Self;
		RPGMenu_TabPage(Tabs.TabStack[i].MyPanel).InitMenu();
	}
}

event Closed(GUIComponent Sender, bool bCancelled)
{
	local int i;

	for(i = 0; i < Tabs.Controls.Length; i++)
		RPGMenu_TabPage(Tabs.Controls[i]).CloseMenu();

	if(RPRI != None)
	{
		RPRI.Interaction.Settings.SaveConfig();
		RPRI.Interaction.CharSettings.SaveConfig();
		RPRI.Menu = None;
	}
	
	if(RPRI.Level.NetMode == NM_Standalone)
		RPRI.Level.Game.SetPause(false, PlayerController(RPRI.Controller));

	Super.Closed(Sender, bCancelled);
}

event Free()
{
	Super.Free();
	RPRI = None;
}

defaultproperties
{
	Panels(0)=(ClassName="RPGMenu_Character",Caption="Character",Hint="View your current character's statistics.")
	Panels(1)=(ClassName="RPGMenu_Abilities",Caption="Buy",Hint="Distribute stat points and buy abilities.")
	Panels(2)=(ClassName="RPGMenu_PlayerLevels",Caption="Player Levels",Hint="See the levels of the currently playing players.")
	Panels(3)=(ClassName="RPGMenu_SettingsMaster",Caption="Settings",Hint="Customize TitanRPG features.")

	bStats=False //should be left as default

	Begin Object Class=GUITabControl Name=RPGMenuTC
		bFillSpace=True
		bDockPanels=True
		TabHeight=0.037500
		BackgroundStyleName="TabBackground"
		WinTop=0.05
		WinLeft=0.01
		WinWidth=0.98
		WinHeight=0.05
		bScaleToParent=True
		bAcceptsInput=True
		OnActivate=RPGMenuTC.InternalOnActivate
	End Object
    Tabs=GUITabControl'RPGMenuTC'
	
	bResizeWidthAllowed=False
	bResizeHeightAllowed=False
	bMoveAllowed=False
	bPersistent=True
    bAllowedAsLast=True
	
	WinLeft=0.10
	WinTop=0.10
	WinWidth=0.80
	WinHeight=0.80

	WindowTitle="TitanRPG Menu"
}
