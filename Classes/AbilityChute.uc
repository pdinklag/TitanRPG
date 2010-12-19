class AbilityChute extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	class'Util'.static.GiveInventory(Other, class'ArtifactChute', true);
}

defaultproperties
{
	AbilityName="Parachute"
	Description="Gives you a parachute that will open up if you are falling too fast, softening your landing."
	StartingCost=10
	CostAddPerLevel=0
	MaxLevel=1
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityIronLegs',Level=1)
}
