class AbilityRetaliation extends RPGAbility;

function HandleDamage(int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	local int RetalDamage;

	if(DamageType == class'DamTypeCounterShove' || DamageType == class'DamTypeRetaliation')
		return;

	if(bOwnedByInstigator || Injured == Instigator || Instigator == None || Injured.Controller == None)
		return;

	if(!Injured.Controller.SameTeamAs(Instigator.Controller))
	{
		RetalDamage = int(float(AbilityLevel) * BonusPerLevel * float(Damage));
		RetalDamage = FMin(RetalDamage, float(Injured.Health));
		
		if(RetalDamage > 0)
		{
			Instigator.TakeDamage(
				RetalDamage,
				Injured,
				Instigator.Location,
				vect(0, 0, 0),
				class'DamTypeRetaliation');
		}
	}
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	BonusPerLevel=0.05
	AbilityName="Retaliation"
	Description="Whenever you are damaged by another player, $1 of the damage per level is also done to the player who hurt you. Does not retaliate against retaliation or counter shove."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=10
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityCounterShove',Level=1)
}
