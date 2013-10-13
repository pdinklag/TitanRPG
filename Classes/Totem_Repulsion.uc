class Totem_Repulsion extends RPGTotem CacheExempt;

var config float Interval;
var config float KnockbackTime, MinKnockbackMomentum, MaxKnockbackMomentum;

auto state Active {
    event BeginState() {
        SetTimer(Interval, true);
    }
    
    function Timer() {
        local Pawn P;
        local vector Dir;
        local Effect_Repulsion Repulsion;
        local FX_RepulsionBeam Beam;
        local float Force;
        
        foreach VisibleCollidingActors(class'Pawn', P, SightRadius, IconLocation) {
            if(P.IsA('xPawn') && xPawn(P).bInvis) {
                continue;
            }
            
            if(P.IsA('Vehicle')) {
                if(Vehicle(P).IsVehicleEmpty() && !Vehicle(P).bAutoTurret)
                    continue;
                
                if(Team != 255 && Vehicle(P).Team == Team)
                    continue;
            }

            if(!Controller.SameTeamAs(P.Controller) && P.Health > 0 && FastTrace(Icon.Location, P.Location)) {
                Repulsion = Effect_Repulsion(class'Effect_Repulsion'.static.Create(P, Instigator.Controller, KnockbackTime));
                if(Repulsion != None) {
                    Dir = P.Location - Location;
                    Force = 1.0 - VSize(Dir) / SightRadius;
                    Dir = Normal(Dir);
                    
                    Repulsion.Momentum = Dir * (MinKnockbackMomentum + Force * (MaxKnockbackMomentum - MinKnockbackMomentum));
                    Repulsion.Start();
                    
                    Beam = Instigator.Spawn(class'FX_RepulsionBeam', Icon);
                    Beam.LinkedPawn = P;
                }
            }
        }
    }
}

defaultproperties {
    Interval=3.0

    KnockbackTime=2.00
	MaxKnockbackMomentum=1500
	MinKnockbackMomentum=250
    
    IconClass=class'TotemIcon_Repulsion'
    VehicleNameString="Repulsive Totem"
}
