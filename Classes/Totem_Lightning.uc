class Totem_Lightning extends RPGTotem CacheExempt;

var config float Interval;
var config int Damage;

var class<xEmitter> HitEmitterClass;

auto state Active {
    event BeginState() {
        SetTimer(Interval, true);
    }
    
    function Timer() {
        local Pawn P;
        local xEmitter HitEmitter;
        local vector HitLocation;
        local int n;
        
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
                HitEmitter = Spawn(HitEmitterClass,,, Icon.Location, rotator(P.Location - Icon.Location));

                if(HitEmitter != None) {
                    HitEmitter.mSpawnVecA = P.Location;
                }

                HitLocation = P.Location;
                HitLocation += vect(-10, 0, 0) >> rotator(P.Location - Icon.Location); //(c) Wulff ? should credit him here ;)

                P.TakeDamage(Damage, Self, HitLocation, vect(0,0,0), class'DamTypeLightningTotem');
                n++;
            }
        }
        
        if(n > 0) {
            PlaySound(Sound'WeaponSounds.BaseFiringSounds.BLightningGunFire', SLOT_Interact);
        }
    }
}

defaultproperties {
    Interval=3.0
    Damage=25
    
    HitEmitterClass=class'XEffects.LightningBolt'
    IconClass=class'TotemIcon_Lightning'
    VehicleNameString="Lightning Totem"
}
