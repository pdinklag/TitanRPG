class Artifact_BioBomb extends ArtifactBase_Blast;

defaultproperties
{
	BlastClass=class'Blast_Bio'

	CostPerSec=75
	HudColor=(R=0)
	ArtifactID="BioBomb"
	Description="Causes a bio glob explosion."
	PickupClass=Class'ArtifactPickup_BioBomb'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.biobomb'
	ItemName="Bio Bomb"
}
