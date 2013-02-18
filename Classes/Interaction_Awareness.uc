class Interaction_Awareness extends RPGBaseInteraction;

var Interaction_Global GlobalInteraction;
var Ability_Awareness Ability;

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
    local int i;
    local float FarAwayInv, Dist, ScaledDist, Height, Pct;
    local vector ScreenPos;
    local Pawn P;
    local Color BarColor;

    if(Ability == None || Ability.AbilityLevel <= 0) {
        return;
    }
    
    if(ViewportOwner.Actor.Pawn == None || ViewportOwner.Actor.Pawn.Health <= 0) {
        return;
    }
    
    FarAwayInv = 1.0f / TeamBeaconMaxDist;

	for(i = 0; i < Ability.Enemies.Length; i++) {
        P = Ability.Enemies[i];
        if(IsPawnVisible(C, P, ScreenPos, Dist)) {
            ScaledDist = TeamBeaconMaxDist * FClamp(0.04f * P.CollisionRadius, 1.0f, 2.0f);

            if(Dist < 0.0f || Dist > 3.0f * ScaledDist) {
                continue;
            }
            
            //Draw height
            Height = P.CollisionHeight * FClamp(0.85f + Dist * 0.85f * FarAwayInv, 1.1f, 1.75f);
            
            //Offset
            ScreenPos = C.WorldToScreen(P.Location + Height * vect(0, 0, 0.75));
            
            //Bar height
            Height = SmallFontHeight * FClamp(1 - Dist / (TeamBeaconMaxDist / 2), 0.5, 1);
            
            if(P.IsA('Vehicle')) {
                Height *= 1.75;
            }
            
            BarColor.A = 255;

            if(Ability.AbilityLevel >= 2 && P.IsA('xPawn') && P.ShieldStrength > 0) {
                //Shield bar
                ScreenPos.Y -= Height + 2;
                Pct = P.ShieldStrength / xPawn(P).ShieldStrengthMax;

                BarColor.R = 255;
                BarColor.G = 240;
                BarColor.B = 0;
                
                DrawBar(C, ScreenPos.X, ScreenPos.Y, BarColor, Pct, 5 * Height, Height, true);
            }

            //Health bar
            if(P.Health > 0) {
                ScreenPos.Y -= Height + 2;
                Pct = float(P.Health) / P.HealthMax;
                
                if(Pct > 0.5) {
                    BarColor.R = byte(255.0 * FClamp(1.0 - (P.HealthMax - (P.HealthMax - P.Health) * 2) / P.HealthMax, 0, 1));
                    BarColor.G = 255;
                    BarColor.B = 0;
                } else {
                    BarColor.R = 255;
                    BarColor.G = byte(255.0 * FClamp(2.0 * P.Health / P.HealthMax, 0, 1));
                    BarColor.B = 0;
                }

                DrawBar(C, ScreenPos.X, ScreenPos.Y, BarColor, Pct, 5 * Height, Height, true);
            }
        }
    }
}

defaultproperties {
    bVisible = true;
}
