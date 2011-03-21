class AbilityMineLayer extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	local class<RPGWeapon> RWClass;

	Super.ModifyPawn(Other);

	RWClass = RPRI.RPGMut.GetRandomWeaponModifier(class'RPGMineLayer', Other);
	RPRI.QueueWeapon(class'RPGMineLayer', RWClass, RWClass.static.GetRandomModifierLevel());
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
