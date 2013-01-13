class Ability_MultiJump extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);

	if(Other.IsA('xPawn'))
	{
		// Increase the number of times a player can jump in mid air
		xPawn(Other).MaxMultiJump = 1 + AbilityLevel;
		xPawn(Other).MultiJumpRemaining = 1 + AbilityLevel;

		// Also increase a bit the amount they jump each time
		//xPawn(Other).MultiJumpBoost = BonusPerLevel * AbilityLevel;
	}
}

defaultproperties
{
	AbilityName="Multi Jump"
	Description="Increases the amount of combined jumps you can perform by one per level (e.g. triple jump, quad jump, etc)."
	MaxLevel=7
	StartingCost=10
	BonusPerLevel=50
	Category=class'AbilityCategory_Movement'
}
