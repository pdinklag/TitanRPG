/*
    An Interaction for anybody joining the server, even Spectators
*/
class Interaction_Global extends RPGBaseInteraction;

var array<FriendlyPawnReplicationInfo> FriendlyPawns;

function PostRender(Canvas C) {
    local int i;
    local float FarAwayInv, Dist, ScaledDist, Scale, Height, Pct;
    local vector ScreenPos;
    local FriendlyPawnReplicationInfo FPRI;
    local Color BarColor;
    local string Text;
    
    FarAwayInv = 1.0f / TeamBeaconMaxDist;

	for(i = 0; i < FriendlyPawns.Length; i++) {
        FPRI = FriendlyPawns[i];
        
        if(FPRI.Pawn != None && IsPawnVisible(C, FPRI.Pawn, ScreenPos, Dist)) {
            ScaledDist = TeamBeaconMaxDist * FClamp(0.04f * FPRI.Pawn.CollisionRadius, 1.0f, 2.0f);

            if(Dist < 0.0f || Dist > 2.0f * ScaledDist) {
                continue;
            }

			if(Dist > ScaledDist) {
                ScreenPos.Z = 0;
                if(VSize(ScreenPos) * VSize(ScreenPos) > 0.02f * Dist * Dist) {
                    continue;
                }
			}

            //Beacon scale
            Scale = FClamp(0.28f * (ScaledDist - Dist) / ScaledDist, 0.1f, 0.25f);

            //Draw height
            Height = FPRI.Pawn.CollisionHeight * FClamp(0.85f + Dist * 0.85f * FarAwayInv, 1.1f, 1.75f);
            
            //Actual beacon position
            ScreenPos = C.WorldToScreen(FPRI.Pawn.Location + Height * vect(0, 0, 1));
            ScreenPos.X -= 0.5f * TeamBeacon.USize * Scale;
            ScreenPos.Y -= 0.5f * TeamBeacon.VSize * Scale;

            //Player name
            if(Dist < TeamBeaconMaxDist && C.ClipX > 600) {
                Text = FPRI.Master.PlayerName;
            }
            
            //Draw beacon
            DrawTeamBeacon(C, ScreenPos.X, ScreenPos.Y, GetTeamBeaconColor(FPRI.Master), Scale, Text);
            
            //Health bar
            if(
                Dist < TeamBeaconMaxDist &&
                ViewportOwner.Actor.PlayerReplicationInfo != None &&
                FPRI.Master.Team == ViewportOwner.Actor.PlayerReplicationInfo.Team
            )
            {
                Height = SmallFontHeight * FClamp(1 - Dist / (TeamBeaconMaxDist / 2), 0.5, 1);
                Pct = float(FPRI.Pawn.Health) / FPRI.Pawn.HealthMax;
                
                if(Pct > 0.5) {
                    BarColor.R = byte(255.0 * FClamp(1.0 - (FPRI.Pawn.HealthMax - (FPRI.Pawn.HealthMax - FPRI.Pawn.Health) * 2) / FPRI.Pawn.HealthMax, 0, 1));
                    BarColor.G = 255;
                    BarColor.B = 0;
                } else {
                    BarColor.R = 255;
                    BarColor.G = byte(255.0 * FClamp(2.0 * FPRI.Pawn.Health / FPRI.Pawn.HealthMax, 0, 1));
                    BarColor.B = 0;
                }
                
                BarColor.A = 255;
                DrawBar(C,
                    ScreenPos.X,
                    ScreenPos.Y - SmallFontHeight - 4 - Height,
                    BarColor, Pct, 5 * Height, Height);
            }
        }
    }
}

event NotifyLevelChange() {
    Super.NotifyLevelChange();
    FriendlyPawns.Length = 0;
}

function AddFriendlyPawn(FriendlyPawnReplicationInfo FPRI) {
    FriendlyPawns[FriendlyPawns.Length] = FPRI;
}

function bool IsFriendlyPawn(Pawn P) {
    local int i;

    for(i = 0; i < FriendlyPawns.Length; i++) {
        if(FriendlyPawns[i].Pawn == P) {
            return true;
        }
    }
    return false;
}

function RemoveFriendlyPawn(FriendlyPawnReplicationInfo FPRI) {
    local int i;

    for(i = 0; i < FriendlyPawns.Length; i++) {
        if(FriendlyPawns[i] == FPRI) {
            FriendlyPawns.Remove(i, 1);
            break;
        }
    }
}

defaultproperties {
	bVisible=True
}
