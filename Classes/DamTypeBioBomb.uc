class DamTypeBioBomb extends DamageType
	abstract;

defaultproperties
{
    DeathString="%o was GOOPIFIED by %k's bio bomb."
	MaleSuicide="%o was GOOPIFIED."
	FemaleSuicide="%o was GOOPIFIED."

	bKUseTearOffMomentum=false
	//bDetonatesGoop=true
	//bDelayedDamage=true
    
    DeathOverlayMaterial=Material'XGameShaders.PlayerShaders.LinkHit'
}

