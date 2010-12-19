class AbilityEnhancedBalance extends RPGAbility;

function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	if(Damage <= 0)
		return;

	if(bOwnedByInstigator)
		Damage *= 1.0 + float(AbilityLevel) * BonusPerLevel;
	else
		Damage *= 1.0 - float(AbilityLevel) * BonusPerLevel;
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Advanced Damage Balance"
	Description="Increases all damage you do and decreases all damage done to you each by $1 per level."
	StartingCost=6
	CostAddPerLevel=1
	MaxLevel=10
	BonusPerLevel=0.025
	RequiredAbilities(0)=(AbilityClass=class'AbilityDamageBonus',Level=3)
	RequiredAbilities(1)=(AbilityClass=class'AbilityDamageReduction',Level=3)
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityEnhancedReduction',Level=1)
	ForbiddenAbilities(1)=(AbilityClass=class'AbilityEnhancedDamage',Level=1)
}
