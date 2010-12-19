class ArtifactPlusTwoModifier extends ArtifactPlusXModifier;

defaultproperties
{
	X=2
	ArtifactID="PlusTwo"
	Description="Adds 2 levels to the weapon's magic if it is at its maximum."
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.plus2mod'
	ItemName="Magic Modifier Plus Two"
}
