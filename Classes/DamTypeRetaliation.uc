class DamTypeRetaliation extends RPGDamageType
    abstract;

defaultproperties {
    StatWeapon=class'DummyWeapon_Retaliation'
    DeathString="%k's strike back was too much for %o."
    bArmorStops=False
    bCausesBlood=False
    bExtraMomentumZ=False
}
