class ArtifactPlusOneModifier extends ArtifactPlusXModifier;

defaultproperties
{
	X=1
	ArtifactID="PlusOne"
	Description="Adds 1 level to the weapon's magic if it is at its maximum."
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.plus1mod'
	ItemName="Magic Modifier Plus One"
}
