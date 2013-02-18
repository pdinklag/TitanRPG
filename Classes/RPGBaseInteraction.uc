/*
    Abstract base class for TitanRPG interaction classes.
    Contains useful stuff such as constants or team beacon and health bar drawing.
*/
class RPGBaseInteraction extends Interaction abstract;

//Colors
var Color TeamBeaconColor[5];
var Color WhiteColor;

//Constants
const SmallFontHeight = 12.0;

//Materials
var Texture HealthBar, HealthBarBorder;
var Texture TeamBeacon;
var float TeamBeaconMaxDist;

//Gets the team color for a PlayerReplicationInfo
function Color GetTeamBeaconColor(PlayerReplicationInfo PRI) {
    if(PRI.Team != None && PRI.Team.TeamIndex >= 0 && PRI.Team.TeamIndex <= 3) {
        return TeamBeaconColor[PRI.Team.TeamIndex];
    } else {
        return TeamBeaconColor[4];
    }
}

//Checks if a Pawn is currently visible on a canvas and if so, calculates view data.
//Pos  -> The pawn's position on the canvas.
//Dist -> The pawn's distance from the camera location considering the camera's current FOV (zoom).
function bool IsPawnVisible(Canvas C, Pawn P, out vector Pos, out float Dist) {
	local vector CamLoc, D;
	local rotator CamRot;
    
    if(P == None || P.Health <= 0 || ViewportOwner.Actor == None) {
        return false;
    }
    
    if(P.IsA('xPawn') && xPawn(P).bInvis) {
        return false;
    }

    //check if in line of sight
    if(!ViewportOwner.Actor.LineOfSightTo(P)) {
        return false;
    }

    //get camera data
    C.GetCameraLocation(CamLoc, CamRot);
    
    //check if behind
    D = P.Location - CamLoc;
    if(D dot vector(CamRot) < 0) {
        return false;
    }
    
    //Calculate output and return true
    Pos = C.WorldToScreen(P.Location);
    Dist = ViewportOwner.Actor.FOVBias * VSize(D);
    
    return true;
}

//Draws an Onslaught health bar styled bar
function DrawBar(Canvas C, float X, float Y, Color Color, float Pct, float XSize, float YSize, optional bool bCenter) {
    local float ActualXSize;
    
    Pct = FMin(Pct, 2); //Prevent overly large bars
    ActualXSize = FMax(XSize, XSize * Pct);
    
    if(bCenter) {
        X -= 0.5 * ActualXSize;
        Y -= 0.5 * YSize;
    }
    
    C.SetPos(X, Y);
    
    C.Style = 9; //STY_AlphaZ
    C.DrawColor = WhiteColor;
    C.DrawTileStretched(HealthBarBorder, ActualXSize, YSize);
    
    if(Pct > 0) {
        C.DrawColor = Color;
        C.DrawTileStretched(HealthBar, XSize * Pct, YSize);
    }
}

//Draws a team beacon
function DrawTeamBeacon(Canvas C, float X, float Y, Color Color, float Scale, optional string Text) {
    local float XL, YL;
    
    C.Style = 9; //STY_AlphaZ
    C.DrawColor = Color;
    C.SetPos(X, Y);
    
    C.DrawTile(
        TeamBeacon,
        TeamBeacon.USize * Scale, TeamBeacon.VSize * Scale,
        0, 0, TeamBeacon.USize, TeamBeacon.VSize);

    if(Text != "") {
        C.Font = C.TinyFont;
        C.StrLen(Text, XL, YL);
        C.SetPos(X, Y - YL);
        C.DrawTextClipped(Text);
    }
}

//Initialize settings
event Initialized() {
    local PlayerController PC;
    
    Super.Initialized();
    
    PC = ViewportOwner.Actor;
    if(PC.IsA('OLTeamPlayerController')) { //CTF4
        TeamBeaconMaxDist = float(PC.GetPropertyText("OLTeamBeaconPlayerInfoMaxDist"));
    } else {
        TeamBeaconMaxDist = PC.TeamBeaconPlayerInfoMaxDist;
    }
    
    TeamBeacon = PC.TeamBeaconTexture;
}

//Remove interaction when map changes
event NotifyLevelChange() {
    Super.NotifyLevelChange();
	Master.RemoveInteraction(Self);
}

defaultproperties {
	TeamBeaconColor(0)=(R=255,G=64,B=64,A=255) //Red
	TeamBeaconColor(1)=(R=64,G=90,B=255,A=255) //Blue
	TeamBeaconColor(2)=(R=64,G=255,B=64,A=255) //Green
	TeamBeaconColor(3)=(R=255,G=224,B=64,A=255) //Gold
	TeamBeaconColor(4)=(B=255,G=255,R=255,A=255) //Neutral
    WhiteColor=(B=255,G=255,R=255,A=255)
    
    HealthBar=Texture'ONSInterface-TX.HealthBar'
    HealthBarBorder=Texture'InterfaceContent.BorderBoxD'
}
