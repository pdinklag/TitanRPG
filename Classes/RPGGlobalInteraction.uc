/*
	An Interaction for anybody joining the server, even Spectators
*/
class RPGGlobalInteraction extends Interaction;

var float IconSize, IconTextSpacing;

function bool ActorVisible(Canvas C, Actor A)
{
	local vector CameraLocation, CamDir;
	local rotator CameraRotation;
	
	C.GetCameraLocation(CameraLocation, CameraRotation);
	CamDir = vector(CameraRotation);

	if((A.Location - CameraLocation) dot CamDir < 0)
		return false;
	
	return A.FastTrace(A.Location, CameraLocation);
}

function DrawOwnerIcon(Canvas C, float X, float Y, Material Icon, string OwnerName)
{
	local float W, XL, YL;

	C.TextSize(OwnerName, XL, YL);
	W = XL + IconSize + IconTextSpacing;
	
	C.Style = 5;

	C.SetPos(X - W * 0.5, Y - IconSize * 0.5);
	C.DrawTile(
		Icon,
		IconSize, IconSize,
		0, 0,
		Icon.MaterialUSize(),
		Icon.MaterialVSize()
	);

	C.SetPos(X - W * 0.5 + IconSize + IconTextSpacing, Y - YL * 0.5);
	C.DrawText(OwnerName);
}

function PostRender(Canvas C)
{
	local PlayerController PC;
	local Actor RefActor;
	local float MaxDist;
	local vector ScreenPos;
	local FriendlyPawnReplicationInfo FPRI;
	local Material Icon;
	
	if(ViewportOwner.GUIController.bActive)
		return;
	
	PC = ViewportOwner.Actor;
	if(PC == None || PC.PlayerReplicationInfo == None)
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
	
	foreach PC.DynamicActors(class'FriendlyPawnReplicationInfo', FPRI)
	{
		if(VSize(FPRI.Pawn.Location - RefActor.Location) < MaxDist && ActorVisible(C, FPRI.Pawn))
		{
			ScreenPos = C.WorldToScreen(FPRI.Pawn.Location + FPRI.Pawn.CollisionHeight * vect(0, 0, 1));
			if(ScreenPos.X >= 0 && ScreenPos.X < C.SizeX && ScreenPos.Y >= 0 || ScreenPos.Y < C.SizeY)
			{
				if(FPRI.Pawn.IsA('Monster'))
					Icon = class'RPGInteraction'.default.MonsterIcon;
				else if(FPRI.Pawn.IsA('ASTurret'))
					Icon = class'RPGInteraction'.default.TurretIcon;
			
				if(FPRI.Master.Team != None)
					C.DrawColor = class'RPGInteraction'.default.HUDColorTeam[FPRI.Master.Team.TeamIndex];
				else
					C.DrawColor = class'RPGInteraction'.default.WhiteColor;
				
				DrawOwnerIcon(C, ScreenPos.X, ScreenPos.Y, Icon, FPRI.Master.PlayerName);
			}
		}
	}
}

event NotifyLevelChange()
{
	Master.RemoveInteraction(Self);
}

defaultproperties
{
	IconSize=16
	IconTextSpacing=3
	bVisible=True
}
