class AbilityMonstersMax extends RPGAbility;

function ModifyRPRI()
{
	RPRI.MaxMonsters += AbilityLevel;
}

defaultproperties
{
	AbilityName="Monster Herder"
	Description="For each level, you are allowed to spawn one additional monster."
	bUseLevelCost=True
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=10
	LevelCost(3)=10
	MaxLevel=4
	RequiredAbilities(0)=(AbilityClass=class'AbilityConjuration',Level=1)
}
