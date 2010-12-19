class MegaCharger extends UltimaCharger;

defaultproperties
{
	bIgnoreUltimaShield=True
	bIgnoreProtectionGun=True

	bAffectInstigator=True
	bAllowDeadInstigator=False

	Radius=2500.000000
	
	ChargeTime=5.000000
	Damage=360.000000
	DamageStages=5

	DamageType=class'DamTypeMegaExplosion'
	ChargeEmitterClass=class'MegaChargeEmitter'
	ExplosionClass=class'MegaExplosion'
}
