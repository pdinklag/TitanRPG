class RPGMenu extends FloatingWindow;

var RPGPlayerReplicationInfo RPRI;

var array<GUITabItem> Panels;

var automated GUITabControl Tabs;

var localized string WindowTitle;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;
	
	MyController.RegisterStyle(class'STY_RPGListSection');
	
	Super.InitComponent(MyController, MyOwner);

	for(i = 0; i < Panels.Length; i++)
	{
		//Prepend package name to class name
		Panels[i].ClassName = "<? echo($packageName); ?>." $ Panels[i].ClassName;
		Tabs.AddTabItem(Panels[i]);
	}
	
	t_WindowTitle.SetCaption(WindowTitle);
	t_WindowTitle.DockedTabs = Tabs;
}

function InitFor(RPGPlayerReplicationInfo Whom)
{
	local int i, NumStats;

	RPRI = Whom;
	
	for(i = 0; i < RPRI.AllAbilities.Length; i++)
	{
		if(RPRI.AllAbilities[i].bIsStat)
			NumStats++;
	}
	
	RPRI.Menu = Self;
	
	i = 0;
	while(i < Tabs.TabStack.Length)
	{
		if(NumStats == 0 && Tabs.TabStack[i].MyPanel.IsA('RPGMenu_Stats'))
		{
			Tabs.RemoveTab("", Tabs.TabStack[i]);
		}
		else
		{
			RPGMenu_TabPage(Tabs.TabStack[i].MyPanel).RPGMenu = Self;
			RPGMenu_TabPage(Tabs.TabStack[i].MyPanel).InitMenu();
			i++;
		}
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

	Super.Closed(Sender, bCancelled);
}

event Free()
{
	Log(Self @ "Free");

	Super.Free();
	RPRI = None;
}

defaultproperties
{
	Panels(0)=(ClassName="RPGMenu_Character",Caption="Character",Hint="View your current character's statistics.")
	Panels(1)=(ClassName="RPGMenu_Stats",Caption="Stats",Hint="Distribute stat points.")
	Panels(2)=(ClassName="RPGMenu_Abilities",Caption="Abilities",Hint="Buy abilities.")
	Panels(3)=(ClassName="RPGMenu_PlayerLevels",Caption="Player Levels",Hint="See the levels of the currently playing players.")
	Panels(4)=(ClassName="RPGMenu_SettingsMaster",Caption="Settings",Hint="Customize TitanRPG features.")

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
