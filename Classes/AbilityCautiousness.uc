class AbilityCautiousness extends RPGAbility;

function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	if(Injured != Instigator || !bOwnedByInstigator || DamageType == class'Fell')
		return;

	Damage -= int(float(Damage) * BonusPerLevel * float(AbilityLevel));
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Cautiousness"
	StatName="Self damage reduction"
	Description="Reduces self damage by $1 per level."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=5
	RequiredAbilities(0)=(AbilityClass=Class'AbilityHealthBonus',Level=3)
	RequiredAbilities(1)=(AbilityClass=Class'AbilityDamageReduction',Level=5)
	BonusPerLevel=0.150000
}
