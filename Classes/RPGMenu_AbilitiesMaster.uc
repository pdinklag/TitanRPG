class RPGMenu_AbilitiesMaster extends RPGMenu_TabPage;

var RPGPlayerReplicationInfo RPRI;

var array<GUITabItem> Panels;
var automated GUITabControl Tabs;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;
	
	Super.InitComponent(MyController, MyOwner);

	for(i = 0; i < Panels.Length; i++)
	{
		//Prepend package name to class name
		Panels[i].ClassName = class'MutTitanRPG'.default.PackageName $ "." $ Panels[i].ClassName;
		Tabs.AddTabItem(Panels[i]);
	}
}

function InitMenu()
{
	local int i;
	
	for(i = 0; i < Tabs.Controls.Length; i++)
	{
		RPGMenu_TabPage(Tabs.Controls[i]).RPGMenu = RPGMenu;
		RPGMenu_TabPage(Tabs.Controls[i]).InitMenu();
	}
}

function CloseMenu()
{
	local int i;

	for(i = 0; i < Tabs.Controls.Length; i++)
		RPGMenu_TabPage(Tabs.Controls[i]).CloseMenu();
	
	RPRI = None;
}

defaultproperties
{
	Panels(0)=(ClassName="RPGMenu_Stats",Caption="Stats",Hint="Distribute stat points.")
	Panels(1)=(ClassName="RPGMenu_Abilities",Caption="Abilities",Hint="Buy abilities.")

	Begin Object Class=GUITabControl Name=RPGMenuTC
        WinWidth=1.0
        WinLeft=0
        WinTop=0
        WinHeight=0.06
        TabHeight=0.037500
        bAcceptsInput=true
        bDockPanels=true
        bBoundToParent=true
        bScaleToParent=true
        bFillSpace=True
		BackgroundStyleName="TabBackground"
	End Object
    Tabs=GUITabControl'RPGMenuTC'
}
