class Ability_EnhancedReduction extends RPGAbility;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Damage = float(Damage) * (1.0 - float(AbilityLevel) * BonusPerLevel);
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
	RequiredAbilities(0)=(AbilityClass=class'Ability_DamageReduction',Level=5)
	ForbiddenAbilities(0)=(AbilityClass=class'Ability_EnhancedDamage',Level=1)
	ForbiddenAbilities(1)=(AbilityClass=class'Ability_EnhancedBalance',Level=1)
	Category=class'AbilityCategory_Damage'
}
