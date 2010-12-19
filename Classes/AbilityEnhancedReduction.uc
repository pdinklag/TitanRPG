class AbilityEnhancedReduction extends RPGAbility;

function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	if(bOwnedByInstigator)
		return; //if the instigator is doing the damage, ignore this.
		
	if(Damage > 0)
		Damage *= 1.0 - float(AbilityLevel) * BonusPerLevel;
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Advanced Damage Reduction"
	Description="Reduces all damage done to you by $1 per level."
	StartingCost=6
	CostAddPerLevel=1
	MaxLevel=10
	BonusPerLevel=0.04
	RequiredAbilities(0)=(AbilityClass=class'AbilityDamageReduction',Level=5)
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityEnhancedDamage',Level=1)
	ForbiddenAbilities(1)=(AbilityClass=class'AbilityEnhancedBalance',Level=1)
}
