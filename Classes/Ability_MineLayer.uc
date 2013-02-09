class Ability_MineLayer extends RPGAbility;

function ModifyRPRI()
{
	Super.ModifyRPRI();

	RPRI.MaxMines += int(BonusPerLevel) * (AbilityLevel - 1);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", int(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Mine Layer"
	BonusPerLevel=1
	Description="Each level of this ability, except for the first, will increase the amount of parasite mines you can deploy at a time by $1."
	MaxLevel=5
	GrantItem(0)=(Level=1,InventoryClass=class'RPGMineLayer')
	bUseLevelCost=True
	LevelCost(0)=5
	LevelCost(1)=5
	LevelCost(2)=10
	LevelCost(3)=10
	Category=class'AbilityCategory_Weapons'
}
