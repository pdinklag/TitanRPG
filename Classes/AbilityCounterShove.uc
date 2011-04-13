class AbilityCounterShove extends RPGAbility;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local float MomentumMod;

	if(DamageType == class'DamTypeCounterShove' || DamageType == class'DamTypeRetaliation')
		return;

	if(InstigatedBy == Injured || InstigatedBy == None || Injured.Controller.SameTeamAs(InstigatedBy.Controller))
		return;

	if(Injured.isA('Vehicle'))
	{
		MomentumMod = -(0.0075 * float(AbilityLevel));
	}
	else		
    {
		if(AbilityLevel < 5)
			MomentumMod = -(0.75 * float(AbilityLevel));
		else
			MomentumMod = -4.00;
	}

	//TODO: RPGEffect
	InstigatedBy.TakeDamage(0, Injured, Instigator.Location, Momentum * MomentumMod * Injured.Mass, class'DamTypeCounterShove');
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
