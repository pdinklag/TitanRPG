class DamTypeMegaExplosion extends RPGDamageType
    abstract;

defaultproperties {
    StatWeapon=Class'DummyWeapon_MegaBlast'
    DeathString="%o was PULVERIZED by the power of %k's blast!"
    FemaleSuicide="%o was PULVERIZED!"
    MaleSuicide="%o was PULVERIZED!"
    bArmorStops=False
    bKUseOwnDeathVel=True
    bDelayedDamage=True
    KDeathVel=600
    KDeathUpKick=600
}
