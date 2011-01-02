class RPGMenu_TabPage extends MidGamePanel;

var RPGMenu RPGMenu;

function InitMenu();
function CloseMenu();

event Closed(GUIComponent Sender, bool bCancelled)
{
	Super.Closed(Sender, bCancelled);
}

event Free()
{
	Log(Self @ "Free");

	Super.Free();
	RPGMenu = None;
}

defaultproperties
{
}
