class AbilityShockTherapy extends RPGAbility;

var config float ReductionPerLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		ReductionPerLevel;
}

function HandleDamage(int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	if(
		ClassIsChildOf(DamageType, class'DamTypeShockBall') ||
		ClassIsChildOf(DamageType, class'DamTypeShockBeam') ||
		ClassIsChildOf(DamageType, class'DamTypeShockCombo')
	)
	{
		if(bOwnedByInstigator)
		{
			//reduce outgoing damage
			Damage = float(Damage) * ReductionPerLevel * float(AbilityLevel);
		}
		else
		{
			//reduce incoming damage
			Damage = float(Damage) * BonusPerLevel * float(AbilityLevel);
		}
	}
}

simulated function string DescriptionText()
{
	return repl(
		repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
		"$2", class'Util'.static.FormatPercent(ReductionPerLevel));
}

defaultproperties
{
	AbilityName="Shock Therapy"
	Description="Reduces all Shock Rifle damage you take by $1 per level, but also decreases all damage you do with a Shock Rifle by $2 per level."
	BonusPerLevel=0.10
	ReductionPerLevel=0.10
	MaxLevel=5
	StartingCost=5
	CostAddPerLevel=5
}
