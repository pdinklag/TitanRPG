class AbilityMineLayer extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	if(Other.FindInventoryType(class'RPGMineLayer') == None)
		class'AbilityLoadedWeapons'.static.GiveWeapon(Other, class'RPGMineLayer', 1); //mine layer with random modifier
}

function ModifyRPRI()
{
	RPRI.MaxMines += AbilityLevel - 1;
}

defaultproperties
{
	AbilityName="Mine Layer"
	Description="You are granted the Mine Layer when you spawn. Each subsequent level of this ability will increase the amount of parasite mines you can deploy at a time."
	MaxLevel=7
	StartingCost=5
}
