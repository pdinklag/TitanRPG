class Totem_Heal extends RPGTotem CacheExempt;

var config float Interval;
var config int HealAmount;

auto state Active {
    event BeginState() {
        SetTimer(Interval, true);
    }
    
    function Timer() {
        local Pawn P;
        local Effect_Heal Heal;
        local FX_Beam Beam;
        
        foreach VisibleCollidingActors(class'Pawn', P, SightRadius, IconLocation) {
            if(P.IsA('Vehicle')) {
                continue;
            }
        
            if(Controller.SameTeamAs(P.Controller) && P.Health < P.HealthMax) {
                Heal = Effect_Heal(class'Effect_Heal'.static.Create(P, RPGTotemController(Controller).Master));
                if(Heal != None) {
                    Heal.HealAmount = HealAmount;
                    Heal.SelfHealingCap = HealAmount;
                    Heal.Start();
                    
                    Beam = Instigator.Spawn(class'FX_HealingBeam', Icon);
                    Beam.LinkedPawn = P;
                }
            }
        }
    }
}

defaultproperties {
    Interval=3.0
    HealAmount=25
    
    IconClass=class'TotemIcon_Heal'
    VehicleNameString="Healing Totem"
}
