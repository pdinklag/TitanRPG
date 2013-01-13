class Ability_IronLegs extends RPGAbility;

var config float MaxFallSpeedBonus, MomentumReduction;

replication
{
	reliable if(Role == Role_Authority)
		MaxFallSpeedBonus, MomentumReduction;
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	Other.MaxFallSpeed = Other.default.MaxFallSpeed * (1.0 + MaxFallSpeedBonus * float(AbilityLevel));
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(Injured != InstigatedBy)
		Momentum -= ((Momentum * MomentumReduction) * AbilityLevel);
}

simulated function string DescriptionText()
{
	return repl(
		repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(MaxFallSpeedBonus)),
		"$2", class'Util'.static.FormatPercent(MomentumReduction));
}

defaultproperties
{
	AbilityName="Iron Legs"
	Description="Reduces falling damage by $1 per level and any momentum taken by $2 per level."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=5
	MaxFallSpeedBonus=0.200000
	MomentumReduction=0.200000
	ForbiddenAbilities(0)=(AbilityClass=class'Ability_CounterShove',Level=1)
	Category=class'AbilityCategory_Damage'
}
