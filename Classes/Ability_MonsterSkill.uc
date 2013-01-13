class Ability_MonsterSkill extends RPGAbility;

function ModifyMonster(Monster M, Pawn Master)
{
	MonsterController(M.Controller).InitializeSkill(
		AIController(M.Controller).Skill + float(AbilityLevel) * BonusPerLevel);
}

defaultproperties
{
	BonusPerLevel=1
	AbilityName="Monster Intelligence"
	Description="Makes your summoned monsters more intelligent per level (increases their difficulty)."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=5
	RequiredAbilities(0)=(AbilityClass=class'Ability_MonsterSummon',Level=1)
	Category=class'AbilityCategory_Monsters'
}
