class Totem_Repair extends RPGTotem CacheExempt;

var config float Interval;
var config int RepairAmount, PowerNodeRepairAmount;

auto state Active {
    event BeginState() {
        SetTimer(Interval, true);
    }
    
    function Timer() {
        local Vehicle V;
        local ONSPowerNode Node;
        local RPGGameObjectiveObserver Observer;
        local FX_Beam Beam;
        local int Amount, n, OldHealth;
        
        foreach CollidingActors(class'Vehicle', V, SightRadius, IconLocation) {
            if(V == Self || !CheckLineOfSight(V)) {
                continue;
            }
        
            if(class'Util'.static.SameTeamP(V, Instigator) && (V.bAutoTurret || !V.IsVehicleEmpty()) && V.Health < V.HealthMax) {
                n++;
            
                Amount = Min(RepairAmount, V.HealthMax - V.Health);
                V.Health += Amount;
                
                if(!class'Util'.static.InVehicle(Instigator, V)) {
                    class'Util'.static.DoHealableDamage(
                        Instigator, V, Amount, class'RPGRules'.default.EXP_VehicleRepair);
                }
               
                Beam = Instigator.Spawn(class'FX_RepairBeam', Icon);
                Beam.LinkedPawn = V;
            }
        }
        
        foreach VisibleCollidingActors(class'ONSPowerNode', Node, SightRadius, IconLocation) {
            if(Team == Node.DefenderTeamIndex && Node.Health < Node.DamageCapacity) {
                OldHealth = Node.Health;
                if(Node.HealDamage(PowerNodeRepairAmount, Instigator.Controller, class'DamTypeLinkShaft')) {
                    if(Node.Health > OldHealth) {
                        n++;
                        
                        Observer = class'RPGGameObjectiveObserver'.static.GetFor(Node);
                        if(Observer != None) {
                            Observer.Healed(RPGTotemController(Controller).Master, Node.Health - OldHealth);
                        }
                        
                        Beam = Instigator.Spawn(class'FX_RepairBeam', Icon);
                        Beam.LinkedLocation = Node.EnergySphere.Location;
                    }
                }
            }
        }
        
        if(n > 0) {
            PlaySound(Sound'WeaponSounds.LinkGun.LinkActivated', SLOT_Interact);
        }
    }
}

function bool CheckLineOfSight(Vehicle V) {
    local Actor X;
    local vector HitLocation, HitNormal;
    local RPGTotemWall Wall;
    
    X = Trace(HitLocation, HitNormal, V.Location, IconLocation, True);
    if(X == V) {
        return True;
    } else if(V.IsA('RPGTotem')) {
        Wall = RPGTotemWall(X);
        return (Wall != None) && RPGTotem(V).ConnectedToWall(Wall);
    } else {
        return False;
    }
}

defaultproperties {
    Interval=3.0
    RepairAmount=35
    PowerNodeRepairAmount=100
    
    IconClass=class'TotemIcon_Repair'
    VehicleNameString="Repair Totem"
}
