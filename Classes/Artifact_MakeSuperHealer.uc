class Artifact_MakeSuperHealer extends ArtifactBase_WeaponMaker;

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	if(WeaponSuperHealer(Other.Weapon) != None)
		return class'RPGWeapon';
	else
		return class'WeaponSuperHealer';
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
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.MedicMaker'
	ItemName="Medic Weapon Maker"
}
