class Ability_EnhancedDamage extends RPGAbility;

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Damage = float(Damage) * (1.0 + float(AbilityLevel) * BonusPerLevel);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Advanced Damage Bonus"
	Description="Increases all damage you do by $1 per level."
	StartingCost=6
	CostAddPerLevel=1
	MaxLevel=10
	BonusPerLevel=0.06
	RequiredAbilities(0)=(AbilityClass=class'Ability_DamageBonus',Level=5)
	ForbiddenAbilities(0)=(AbilityClass=class'Ability_EnhancedReduction',Level=1)
	ForbiddenAbilities(1)=(AbilityClass=class'Ability_EnhancedBalance',Level=1)
	Category=class'AbilityCategory_Damage'
}