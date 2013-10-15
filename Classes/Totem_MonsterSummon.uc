class Totem_MonsterSummon extends RPGTotem CacheExempt;

var config float InitialDelay, Interval;
var config array<class<Monster> > MonsterTypes;

auto state Active {
    event BeginState() {
        SetTimer(InitialDelay, false);
    }
    
    function Timer() {
        local class<Monster> Type;
        local vector Off;
        local int Tries;
        local Monster M;
        local Controller Master;
        local FriendlyMonsterController C;
        local FX_SummonBeam Beam;
        local RPGPlayerReplicationInfo RPRI;
    
        Master = RPGTotemController(Controller).Master;
        if(Master != None && Master.Pawn != None && MonsterTypes.Length > 0) {
            Type = MonsterTypes[Rand(MonsterTypes.Length)];
            
            while(M == None && Tries < 25) {
                Tries++;
                
                Off = VRand() * 2.5 * (CollisionRadius * DrawScale + Type.default.CollisionRadius * Type.default.DrawScale);
                Off.Z = 32;
                
                M = Master.Pawn.Spawn(Type, Master,, Location + Off, rotator(Off));
                if(M != None) {
                    if(M.Controller != None)
                        M.Controller.Destroy();

                    C = Spawn(class'FriendlyMonsterController',,, M.Location, M.Rotation);
                    C.Possess(M);
                    C.SetMaster(Master);
                    
                    RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Master);
                    if(RPRI != None) {
                        RPRI.ModifyMonster(M);
                    }
                    
                    Beam = Instigator.Spawn(class'FX_SummonBeam', Icon);
                    Beam.LinkedPawn = M;
                    break;
                }
            }
        }
        
        SetTimer(Interval, true);
    }
}

defaultproperties {
    InitialDelay=5.0
    Interval=45.0
    MonsterTypes(0)=class'SkaarjPack.Krall'
    
    IconClass=class'TotemIcon_MonsterSummon'
    VehicleNameString="Summoning Totem"
}
