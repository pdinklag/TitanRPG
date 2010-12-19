class AbilityTurretsMax extends RPGAbility;

function ModifyRPRI()
{
	RPRI.MaxTurrets += AbilityLevel;
}

defaultproperties
{
	AbilityName="Turret Control Center"
	Description="For each level, you are allowed to construct one additional turret."
	bUseLevelCost=True
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=10
	LevelCost(3)=10
	MaxLevel=4
	RequiredAbilities(0)=(AbilityClass=class'AbilityConstruction',Level=1)
}
