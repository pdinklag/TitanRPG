/*
	An Interaction for anybody joining the server, even Spectators
*/
class RPGGlobalInteraction extends Interaction;

var Color TeamBeaconColor[5];

function bool IsLocationVisible(Canvas C, vector Location, Actor RefActor)
{
	local vector CameraLocation, CamDir;
	local rotator CameraRotation;
	
	if(
		RefActor.Region.Zone != None && 
		RefActor.Region.Zone.bDistanceFog &&
		VSize(CameraLocation - Location) >= RefActor.Region.Zone.DistanceFogEnd
	)
	{
		//can't see when it's too foggy
		return false;
	}
	
	C.GetCameraLocation(CameraLocation, CameraRotation);
	CamDir = vector(CameraRotation);

	if((Location - CameraLocation) dot CamDir < 0)
		return false;
	
	return RefActor.FastTrace(Location, CameraLocation);
}

function DrawBeacon(Canvas C, float X, float Y, float Scale, int Team, string Text)
{
	local Texture BeaconTex;
	local float XL,YL;
	
	C.Font = C.TinyFont;

	BeaconTex = ViewportOwner.Actor.TeamBeaconTexture; //TODO
	if(BeaconTex == None)
		return;

	if(Team >= 0 && Team <= 3)
		C.DrawColor = TeamBeaconColor[Team];
	else
		C.DrawColor = TeamBeaconColor[4];

	if(Text != "")
	{
		C.StrLen(Text, XL, YL);
		C.SetPos(X - 0.125 * BeaconTex.USize , Y - 0.125 * BeaconTex.VSize - YL);
		C.DrawTextClipped(Text);
	}

	C.SetPos(X - Scale * 0.125 * BeaconTex.USize, Y - Scale * 0.125 * BeaconTex.VSize);
	C.DrawTile(BeaconTex,
		Scale * 0.25 * BeaconTex.USize,
		Scale * 0.25 * BeaconTex.VSize,
		0.0,
		0.0,
		BeaconTex.USize,
		BeaconTex.VSize);
}

function PostRender(Canvas C)
{
	local PlayerController PC;
	local Actor RefActor;
	local float MaxDist, Dist;
	local vector ScreenPos;
	local FriendlyPawnReplicationInfo FPRI;
	local vector FriendlyPawnLocation;
	local HudCDeathmatch HUD;
	local string Text;
	local int Team;
	local vector CamLoc;
	local rotator CamRot;

	PC = ViewportOwner.Actor;
	if(PC == None || PC.PlayerReplicationInfo == None)
		return;

	HUD = HudCDeathmatch(ViewportOwner.Actor.myHUD);
	if(HUD == None)
		return;

	if(PC.IsA('OLTeamPlayerController'))
		MaxDist = float(PC.GetPropertyText("OLTeamBeaconPlayerInfoMaxDist"));
	else
		MaxDist = PC.TeamBeaconPlayerInfoMaxDist;
	
	if(PC.ViewTarget != None)
		RefActor = PC.ViewTarget;
	else if(PC.Pawn != None)
		RefActor = PC.Pawn;
	else
		RefActor = PC;
	
	C.GetCameraLocation(CamLoc, CamRot);

	foreach PC.DynamicActors(class'FriendlyPawnReplicationInfo', FPRI)
	{
		if(FPRI.Pawn != None)
			FriendlyPawnLocation = FPRI.Pawn.Location;
		else
			FriendlyPawnLocation = FPRI.PawnLocation;
	
		Dist = VSize(FriendlyPawnLocation - CamLoc) * PC.FOVBias; //considers zoom etc
		if(Dist < MaxDist * 2.0f && IsLocationVisible(C, FriendlyPawnLocation, RefActor))
		{
			ScreenPos = C.WorldToScreen(
				FriendlyPawnLocation +
				FPRI.PawnHeight *
				1.1f *
				vect(0, 0, 1));
			
			if(ScreenPos.X >= 0 && ScreenPos.X < C.SizeX && ScreenPos.Y >= 0 || ScreenPos.Y < C.SizeY)
			{
				if(Dist < MaxDist)
				{
					Text = FPRI.Master.PlayerName;
					if(PC.PlayerReplicationInfo == FPRI.Master)
						Text @= "(" $ FPRI.PawnHealth $ ")";
				}
				else
				{
					Text = "";
				}
				
				if(FPRI.Master.Team != None)
					Team = FPRI.Master.Team.TeamIndex;
				else
					Team = 255;
			
				DrawBeacon(C, ScreenPos.X, ScreenPos.Y, 1.0f /*FMax(0.5f, 1.0f - FMax(0.0f, (Dist - MaxDist) / MaxDist))*/, Team, Text);
			}
		}
	}
	
	//reset
	C.DrawColor = C.default.DrawColor;
}

event NotifyLevelChange()
{
	Master.RemoveInteraction(Self);
}

defaultproperties
{
	bVisible=True

	TeamBeaconColor(0)=(R=255,G=64,B=64,A=255)
	TeamBeaconColor(1)=(R=64,G=90,B=255,A=255)
	TeamBeaconColor(2)=(R=64,G=255,B=64,A=255)
	TeamBeaconColor(3)=(R=255,G=224,B=64,A=255)
	TeamBeaconColor(4)=(B=255,G=255,R=255,A=255)
}
