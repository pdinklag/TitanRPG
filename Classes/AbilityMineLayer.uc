class AbilityMineLayer extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	if(Other.FindInventoryType(class'RPGMineLayer') == None)
		class'AbilityLoadedWeapons'.static.GiveWeapon(Other, class'RPGMineLayer', 1); //mine layer with random modifier
}

function ModifyRPRI()
{
	RPRI.MaxMines += int(BonusPerLevel) * AbilityLevel;
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", int(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Mine Layer"
	BonusPerLevel=1
	Description="You are granted the Mine Layer when you spawn. Each level of this ability will increase the amount of parasite mines you can deploy at a time by $1."
	MaxLevel=6
	StartingCost=5
}
