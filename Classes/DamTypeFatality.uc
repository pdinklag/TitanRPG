class DamTypeFatality extends DamageType
	abstract;

defaultproperties
{
	DeathString="%o was fatalized by an admin."
	MaleSuicide="%o was fatalized by an admin."
	FemaleSuicide="%o was fatalized by an admin."

    bSuperWeapon=true
    bArmorStops=false
    bDelayedDamage=true

	bCausedByWorld=true
	bKUseOwnDeathVel=true
	KDeathVel=600
	KDeathUpKick=600
	
	bFlaming=true
	bAlwaysGibs=true
	GibModifier=5.0
	GibPerterbation=0.30
	bCausesBlood=true
}
