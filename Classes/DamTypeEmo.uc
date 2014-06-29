class DamTypeEmo extends RPGDamageType
    abstract;

var localized string MaleSuicides[3], FemaleSuicides[3];

static function string DeathMessage(PlayerReplicationInfo Killer, PlayerReplicationInfo Victim)
{
	//Emos can't kill, only suicide. :D
	return static.SuicideMessage(Victim);
}

static function string SuicideMessage(PlayerReplicationInfo Victim)
{
	if ( Victim.bIsFemale )
		return default.FemaleSuicides[Rand(3)];
	else
		return default.MaleSuicides[Rand(3)];
}

defaultproperties {
    StatWeapon=class'DummyWeapon_Emo'
    MaleSuicides(0)="%o got all emotional."
    MaleSuicides(1)="Things got too much for %o."
    MaleSuicides(2)="%o couldn't take any more."
    FemaleSuicides(0)="%o got all emotional."
    FemaleSuicides(1)="Things got too much for %o."
    FemaleSuicides(2)="%o couldn't take any more."
    bArmorStops=False
    bLocationalHit=False
    bAlwaysSevers=True
    GibPerterbation=1.000000
}
