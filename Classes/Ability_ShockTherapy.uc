class Ability_ShockTherapy extends RPGAbility;

var config float ReductionPerLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		ReductionPerLevel;
}

function bool IsShockDamage(class<DamageType> DamageType)
{
	return
		ClassIsChildOf(DamageType, class'DamTypeShockBall') ||
		ClassIsChildOf(DamageType, class'DamTypeShockBeam') ||
		ClassIsChildOf(DamageType, class'DamTypeShockCombo');
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(IsShockDamage(DamageType))
		Damage -= float(Damage) * BonusPerLevel * float(AbilityLevel);
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(IsShockDamage(DamageType))
		Damage -= float(Damage) * ReductionPerLevel * float(AbilityLevel);
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
	Category=class'AbilityCategory_Damage'
}
