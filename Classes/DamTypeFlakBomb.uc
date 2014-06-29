class DamTypeFlakBomb extends RPGDamageType
    abstract;

defaultproperties {
    StatWeapon=Class'DummyWeapon_FlakBomb'
    DeathString="%o was ate some flak from %k's flak bomb."
    MaleSuicide="%o ate his own flak."
    FemaleSuicide="%o was ate her own flak."

    GibPerterbation=0.25
    bDetonatesGoop=true
    bThrowRagdoll=true
}
