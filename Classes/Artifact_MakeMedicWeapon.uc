class Artifact_MakeMedicWeapon extends ArtifactBase_WeaponMaker hidedropdown;

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	if(Weapon_Medic(Other.Weapon) != None)
		return class'RPGWeapon';
	else
		return class'Weapon_Medic';
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
