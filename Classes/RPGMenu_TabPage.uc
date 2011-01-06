class RPGMenu_TabPage extends MidGamePanel;

var RPGMenu RPGMenu;

function InitMenu();
function CloseMenu();

event Closed(GUIComponent Sender, bool bCancelled)
{
	Super.Closed(Sender, bCancelled);
	RPGMenu = None;
}

defaultproperties
{
}
