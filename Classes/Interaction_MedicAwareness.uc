class Interaction_MedicAwareness extends RPGBaseInteraction;

var Interaction_Global GlobalInteraction;
var Ability_MedicAwareness Ability;

event Initialized() {
    local int i;
    
    Super.Initialized();

    for(i = 0; i < ViewportOwner.LocalInteractions.Length; i++) {
        if(ViewportOwner.LocalInteractions[i].IsA('Interaction_Global')) {
            GlobalInteraction = Interaction_Global(ViewportOwner.LocalInteractions[i]);
            break;
        }
    }
}

function PostRender(Canvas C) {
    local int i, k;
    local float FarAwayInv, Dist, ScaledDist, Scale, Height, Pct;
    local vector ScreenPos;
    local Pawn P;
    local Color BarColor;
    local Texture BeaconTexture;
    local xPlayer xPC;

    if(Ability == None || Ability.AbilityLevel <= 0) {
        return;
    }
    
    if(ViewportOwner.Actor.Pawn == None || ViewportOwner.Actor.Pawn.Health <= 0) {
        return;
    }
    
    xPC = xPlayer(ViewportOwner.Actor);
    
    FarAwayInv = 1.0f / TeamBeaconMaxDist;

	for(i = 0; i < Ability.Teammates.Length; i++) {
        P = Ability.Teammates[i];
        if(IsPawnVisible(C, P, ScreenPos, Dist)) {
            ScaledDist = TeamBeaconMaxDist * FClamp(0.04f * P.CollisionRadius, 1.0f, 2.0f);

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
            Height = P.CollisionHeight * FClamp(0.85f + Dist * 0.85f * FarAwayInv, 1.1f, 1.75f);
            
            //Offset, including the team beacon and text!
            ScreenPos = C.WorldToScreen(P.Location + Height * vect(0, 0, 1));
            
            //Check if speaking (see UnPawn.cpp)
            if(
                xPC != None &&
                xPC.myHUD.PortraitPRI != None &&
                xPC.myHUD.PortraitPRI == P.PlayerReplicationInfo
            ) {
                BeaconTexture = xPC.SpeakingBeaconTexture;
                Scale *= 3;
            } else {
                if(xPC != None) {
                    for(k = 0; k < P.Attached.Length; k++) {
                        if(P.Attached[k].IsA('WeaponAttachment') && WeaponAttachment(P.Attached[k]).bMatchWeapons) {
                            BeaconTexture = xPC.LinkBeaconTexture;
                            k = 999; //inner break
                        }
                    }
                }
                
                if(BeaconTexture == None) {
                    BeaconTexture = TeamBeacon;
                }
            }
            
            ScreenPos.X -= 0.5f * BeaconTexture.USize * Scale;
            ScreenPos.Y -= 0.5f * BeaconTexture.VSize * Scale;
            
            //Text
            if(Dist < TeamBeaconMaxDist && C.ClipX > 600) {
                ScreenPos.Y -= SmallFontHeight;
            }
            
            //Bar height
            Height = SmallFontHeight * FClamp(1 - Dist / (TeamBeaconMaxDist / 2), 0.5, 1);
            
            if(P.IsA('Vehicle')) {
                Height *= 1.75;
            }
            
            BarColor.A = 255;

            //Health bar
            ScreenPos.Y -= Height + 4;
            Pct = float(P.Health) / P.HealthMax;
            
            BarColor = GetTeamBeaconColor(P.PlayerReplicationInfo);
            BarColor.R = byte(FMin(255, float(BarColor.R) * 1.67 * FClamp(Pct, 0.33, 1.0)));
            BarColor.G = byte(FMin(255, float(BarColor.G) * 1.67 * FClamp(Pct, 0.33, 1.0)));
            BarColor.B = byte(FMin(255, float(BarColor.B) * 1.67 * FClamp(Pct, 0.33, 1.0)));

            DrawBar(C, ScreenPos.X, ScreenPos.Y, BarColor, Pct, 5 * Height, Height);
        }
    }
}

defaultproperties {
    bVisible = true;
}
