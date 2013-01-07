class Ability_BoostDodging extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);

	if(xPawn(Other) != None)
		xPawn(Other).bCanBoostDodge = true;
}

defaultproperties
{
	AbilityName="Boost Dodging"
	Description="Allows you to boost dodge like in UT2003."
	MaxLevel=1
	StartingCost=10
	Category=class'AbilityCategory_Movement'
}
