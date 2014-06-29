//Base for blasts that spawn projectiles
class Blast_Projectile extends Blast abstract;

var config class<Projectile> ProjectileClass;

var config int NumProjectiles;
var config float SpeedMin, SpeedMax;

var config bool bOnlyUpwards;
var config float SpawnRadius;

function DoEffect() {
    local vector Dir;
    local Projectile Proj;
    local int i;
    
    for(i = 0; i < NumProjectiles; i++) {
        Dir = VRand();
        
        if(bOnlyUpwards && Dir.Z < 0) {
            Dir.Z = -Dir.Z;
        }
        
        Proj = Instigator.Spawn(ProjectileClass,,, Location + Dir * SpawnRadius, rotator(Dir));

        if(Proj != None) {
            Proj.Velocity = Dir * (SpeedMin + FRand() * (SpeedMax - SpeedMin));
        }
    }

    Destroy();
}

defaultproperties {
    SpawnRadius=16
    bOnlyUpwards=True

    bBotsBeAfraid=True
    ChargeTime=2.00
    Radius=1536
    ExplosionClass=None
    ExplosionSound=None //none necessary really
}
