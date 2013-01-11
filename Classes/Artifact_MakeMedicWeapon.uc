class Artifact_MakeMedicWeapon extends ArtifactBase_WeaponMaker hidedropdown;

function class<RPGWeaponModifier> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	if(class'WeaponModifier_Medic'.static.GetFor(Other.Weapon) != None)
		return None;
	else
		return class'WeaponModifier_Medic';
}

defaultproperties
{
	CostPerSec=5
	MinActivationTime=1.000000
	HudColor=(B=255,G=128,R=0)
	ArtifactID="MedicMaker"
	bCanBeTossed=False
	bAvoidRepetition=False
	Description="Generates a medic weapon."
	IconMaterial=Texture'TitanRPG.ArtifactIcons.MedicMaker'
	ItemName="Medic Weapon Maker"
}
