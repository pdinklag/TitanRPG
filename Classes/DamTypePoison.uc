class DamTypePoison extends RPGDamageType
    abstract;

defaultproperties {
    StatWeapon=class'DummyWeapon_Poison'
    DeathString="%o couldn't find an antidote for %k's poison."
    FemaleSuicide="%o poisoned herself."
    MaleSuicide="%o poisoned himself."
    bArmorStops=False
    bCausesBlood=False
    bExtraMomentumZ=False
    bDelayedDamage=True
}
