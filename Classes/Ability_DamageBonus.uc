class Ability_DamageBonus extends RPGAbility;

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
	AbilityName="Damage Bonus"
	Description="Increases all damage you do by $1 per level."
	MaxLevel=6
	StartingCost=5
	BonusPerLevel=0.025
	Category=class'AbilityCategory_Damage'
}
