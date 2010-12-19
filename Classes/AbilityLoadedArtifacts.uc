class AbilityLoadedArtifacts extends RPGAbility;

var config int ProtectArtifactsLevel;

function bool ProtectArtifacts()
{
	return (AbilityLevel >= ProtectArtifactsLevel);
}

defaultproperties
{
	ProtectArtifactsLevel=2 //TitanRPG, ONSRPG would be 3
	AbilityName="Loaded Artifacts"
	Description="You are given magic artifacts when you spawn."
	StartingCost=20
	CostAddPerLevel=20
	MaxLevel=2
	RequiredAbilities(0)=(AbilityClass=class'AbilityAdrenalineSurge',Level=1)
	RequiredAbilities(1)=(AbilityClass=class'AbilityEnergyLeech',Level=1)
	RequiredAbilities(2)=(AbilityClass=class'AbilityAdrenalineRegen',Level=1)
}
