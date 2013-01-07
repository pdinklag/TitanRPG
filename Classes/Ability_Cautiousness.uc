class Ability_Cautiousness extends RPGAbility;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(InstigatedBy == Injured && DamageType != class'Fell')
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
	BonusPerLevel=0.150000
	Category=class'AbilityCategory_Damage'
}
