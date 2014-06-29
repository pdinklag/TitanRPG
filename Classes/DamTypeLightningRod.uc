class DamTypeLightningRod extends RPGDamageType
    abstract;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictemHealth)
{
    HitEffects[0] = class'HitSmoke';
    if (Rand(25) > VictemHealth)
	HitEffects[1] = class'HitFlame';
}

defaultproperties {
    StatWeapon=class'DummyWeapon_LightningRod'
    DeathString="%o was electrocuted by %k's lightning rod."
    FemaleSuicide="%o had an electrifying experience."
    MaleSuicide="%o had an electrifying experience."
    bCauseConvulsions=True
    DamageOverlayMaterial=Shader'XGameShaders.PlayerShaders.LightningHit'
    DamageOverlayTime=1.000000
    GibPerterbation=0.250000
}
