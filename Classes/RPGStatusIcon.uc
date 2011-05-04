//client side only
class RPGStatusIcon extends Object;

var RPGPlayerReplicationInfo RPRI;

var Material IconMaterial; //the icon texture to display

//abstract
function Initialize(); //initialize, the RPRI is already set at this point

function bool IsVisible(); //determines whether this icon should currently be displayed
function string GetText(); //retrieves the text to display on this icon

defaultproperties
{
}
