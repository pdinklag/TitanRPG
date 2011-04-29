class Blast_Mega extends Blast_Ultima;

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
	ChargeEmitterClass=class'FX_BlastCharger_Mega'
	ExplosionClass=class'FX_BlastExplosion_Mega'
}
