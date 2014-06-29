class DamTypeRepulsion extends RPGDamageType
    abstract;

defaultproperties {
    StatWeapon=Class'DummyWeapon_Repulsion'
    DeathString="%o threw %k out of this world."
    FemaleSuicide="%o threw herself out of this world."
    MaleSuicide="%o threw himself out of this world."
    bDelayedDamage=True
}
