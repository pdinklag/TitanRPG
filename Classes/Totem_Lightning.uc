class Totem_Lightning extends RPGTotem
    config(TitanRPG);

var config int Damage;

function FireAt(Actor Other) {
    local xEmitter HitEmitter;
    local vector HitLocation;

    if(!class'Util'.static.IsFriendly(TeamNum, Other)) {
        if(FastTrace(IndicatorLocation, Other.Location)) {
            class'Util'.static.PlayLoudEnoughSound(Self, Sound'WeaponSounds.LightningGun.LightningGunFire');
        
            HitLocation = Other.Location;
            HitLocation += vect(-10, 0, 0) >> rotator(Other.Location - IndicatorLocation); //(c) Wulff ? should credit him here ;)
        
            Other.TakeDamage(Damage, Instigator, HitLocation, vect(0, 0, 0), class'DamTypeLightningTotem');
        
            HitEmitter = Spawn(class'XEffects.LightningBolt',,, IndicatorLocation, rotator(Other.Location - IndicatorLocation));
            if(HitEmitter != None)
                HitEmitter.mSpawnVecA = Other.Location;
        }
    }
}

defaultproperties {
    Damage=25
    Interval=3

    AffectedClass=class'Actor'
    IndicatorClass=class'TotemIndicator_Lightning'
}
