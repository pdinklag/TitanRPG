class AbilityCounterShove extends RPGAbility;

function HandleDamage(int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	local float MomentumMod;

	if(DamageType == class'DamTypeCounterShove' || DamageType == class'DamTypeRetaliation')
		return;

	if(bOwnedByInstigator || Injured == Instigator || Instigator == None || (Injured != None && Instigator != None && Injured.GetTeamNum() == Instigator.GetTeamNum()))
		return;

	//negative values to reverse direction

	if (Injured.isA('Vehicle'))
	{
		MomentumMod = - (0.0075 * AbilityLevel);
	}
	else		
    {
		if (AbilityLevel < 5)
			MomentumMod = - (0.75 * AbilityLevel);
		else
			MomentumMod = -4.00;
	}

	Instigator.TakeDamage(0, Injured, Instigator.Location, (Momentum * Injured.Mass) * MomentumMod, class'DamTypeCounterShove');
}

defaultproperties
{
	AbilityName="Counter Shove"
	Description="Whenever you are damaged by another player, 75% of the momentum per level is also done to the player who hurt you (or 400% at level 5)|Will not counter counter shove or retaliation."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=5
	RequiredAbilities(0)=(AbilityClass=Class'AbilityDamageReduction',Level=6)
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityIronLegs',Level=1)
	GrantItem(0)=(Level=3,InventoryClass=class'ArtifactRepulsion')
}
