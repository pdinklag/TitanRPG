class Ability_DamageReduction extends RPGAbility;

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    if(Injured != InstigatedBy) {
        Damage = float(Damage) * (1.0 - float(AbilityLevel) * BonusPerLevel);
    }
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Damage Reduction"
	Description="Reduces all damage you take by $1 per level."
	MaxLevel=6
	StartingCost=5
	BonusPerLevel=0.025
	Category=class'AbilityCategory_Damage'
}
