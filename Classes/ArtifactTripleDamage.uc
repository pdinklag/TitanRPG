class ArtifactTripleDamage extends ArtifactUDamage;

defaultproperties
{
	UDamageScale=1.500000
	CostPerSec=13
	ArtifactID="Triple"
	Description="Makes you deal three times as much damage as usual."
	PickupClass=Class'ArtifactPickupTripleDamage'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.Triple'
	ItemName="Triple Damage"
}
