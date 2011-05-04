/*
	An Interaction for anybody joining the server, even Spectators
*/
class RPGGlobalInteraction extends Interaction;

var Color TeamBeaconColor[5];

var array<FriendlyPawnReplicationInfo> FriendlyPawns;

function PostRender(Canvas C)
{
	if(FriendlyPawns.Length > 0)
		RenderFriendlyPawnsInfo(C);
}

function RenderFriendlyPawnsInfo(Canvas C)
{
	local int i;
	local Texture TeamBeacon;
	local PlayerController PC;
	local float Dist, ScaledDist, TeamBeaconPlayerInfoMaxDist, FarAwayInv, Height, XScale, XL, YL;
	local vector ScreenPos;
	local FriendlyPawnReplicationInfo FPRI;
	local string Text;
	local vector CamLoc;
	local rotator CamRot;

	PC = ViewportOwner.Actor;
	if(PC == None || PC.PlayerReplicationInfo == None)
		return;

	if(PC.IsA('OLTeamPlayerController')) //CTF4
		TeamBeaconPlayerInfoMaxDist = float(PC.GetPropertyText("OLTeamBeaconPlayerInfoMaxDist"));
	else
		TeamBeaconPlayerInfoMaxDist = PC.TeamBeaconPlayerInfoMaxDist;
	
	TeamBeacon = ViewportOwner.Actor.TeamBeaconTexture;
	FarAwayInv = 1.0f / TeamBeaconPlayerInfoMaxDist;
	
	C.GetCameraLocation(CamLoc, CamRot);
	
	for(i = 0; i < FriendlyPawns.Length; i++)
	{
		FPRI = FriendlyPawns[i];
		
		if(FPRI.Pawn != None)
		{
			//check if behind
			if((FPRI.Pawn.Location - CamLoc) dot vector(CamRot) < 0)
				continue;
		
			/*
				Translated and optimized from C++ code (UnPawn.cpp)
			*/
			
			//Determine visibility
			if(!PC.LineOfSightTo(FPRI.Pawn))
				continue;
		
			Dist = PC.FOVBias * VSize(FPRI.Pawn.Location - CamLoc);
			ScaledDist = TeamBeaconPlayerInfoMaxDist * FClamp(0.04f * FPRI.Pawn.CollisionRadius, 1.0f, 2.0f);
			
			ScreenPos = C.WorldToScreen(FPRI.Pawn.Location);
			
			if(Dist < 0.0f || Dist > 2.0f * ScaledDist)
				continue;
			
			if(Dist > ScaledDist)
			{
				ScreenPos.Z = 0;
				if(VSize(ScreenPos) * VSize(ScreenPos) > 0.02f * Dist * Dist)
					continue;
			}

			//Color
			if(FPRI.Master.Team != None)
				C.DrawColor = TeamBeaconColor[FPRI.Master.Team.TeamIndex];
			else
				C.DrawColor = TeamBeaconColor[4];
			
			//Beacon scale
			XScale = FClamp(0.28f * (ScaledDist - Dist) / ScaledDist, 0.1f, 0.25f);
			
			//Draw height
			Height = FPRI.Pawn.CollisionHeight * FClamp(0.85f + Dist * 0.85f * FarAwayInv, 1.1f, 1.75f);
			
			//ScreenPos
			ScreenPos = C.WorldToScreen(FPRI.Pawn.Location + Height * vect(0, 0, 1));
			ScreenPos.X -= 0.5f * TeamBeacon.USize * XScale;
			ScreenPos.Y -= 0.5f * TeamBeacon.VSize * XScale;

			//Draw
			C.Style = 9; //STY_AlphaZ
			C.SetPos(ScreenPos.X, ScreenPos.Y);
			
			C.DrawTile(
				TeamBeacon,
				TeamBeacon.USize * XScale, TeamBeacon.VSize * XScale,
				0, 0, TeamBeacon.USize, TeamBeacon.VSize);

			//Text
			if(Dist < TeamBeaconPlayerInfoMaxDist && C.ClipX > 600)
			{
				C.Font = C.TinyFont;
				
				Text = FPRI.Master.PlayerName;
				if(FPRI.Master.Team == PC.PlayerReplicationInfo.Team)
					Text @= "(" $ FPRI.Pawn.Health $ ")";
				
				C.StrLen(Text, XL, YL);
				C.SetPos(ScreenPos.X, ScreenPos.Y - YL);
				C.DrawTextClipped(Text);
			}
		}
		else
		{
			Log("FPRI.Pawn is None!", 'DEBUG');
		}
	}
	
	//reset
	C.DrawColor = C.default.DrawColor;
}

event NotifyLevelChange()
{
	FriendlyPawns.Length = 0;
	Master.RemoveInteraction(Self);
}

function AddFriendlyPawn(FriendlyPawnReplicationInfo FPRI)
{
	FriendlyPawns[FriendlyPawns.Length] = FPRI;
}

function RemoveFriendlyPawn(FriendlyPawnReplicationInfo FPRI)
{
	local int i;
	
	for(i = 0; i < FriendlyPawns.Length; i++)
	{
		if(FriendlyPawns[i] == FPRI)
		{
			FriendlyPawns.Remove(i, 1);
			break;
		}
	}
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
