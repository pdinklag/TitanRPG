//client side only
class RPGStatusIcon extends Object;

var RPGPlayerReplicationInfo RPRI;

var Material IconMaterial; //the icon texture to display
var bool bShouldTick; //whether Tick is called each frame or not

//abstract
function Initialize(); //initialize, the RPRI is already set at this point
function Tick(float dt); //tick

function bool IsVisible(); //determines whether this icon should currently be displayed
function string GetText(); //retrieves the text to display on this icon

defaultproperties
{
}
