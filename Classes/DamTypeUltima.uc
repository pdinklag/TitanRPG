class DamTypeUltima extends RPGDamageType
	abstract;

defaultproperties {
    StatWeapon=class'DummyWeapon_Ultima'
    DeathString="%o was PULVERIZED by the power of %k's vengeance!"
    FemaleSuicide="%o was PULVERIZED!"
    MaleSuicide="%o was PULVERIZED!"
    bArmorStops=False
    bKUseOwnDeathVel=True
    bDelayedDamage=True
    KDeathVel=600.000000
    KDeathUpKick=600.000000
}
