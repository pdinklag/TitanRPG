class SanctuaryMutator extends Mutator
	HideDropDown
	CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local int i;

	if(Other.IsA('UnrealPawn'))
	{
		//You start with nothing
		for(i = 0; i < ArrayCount(UnrealPawn(Other).RequiredEquipment); i++)
			UnrealPawn(Other).RequiredEquipment[i] = "";
	}
	
	return Super.CheckReplacement(Other, bSuperRelevant);
}

defaultproperties
{
}
