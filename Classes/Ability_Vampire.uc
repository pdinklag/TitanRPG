class Ability_Vampire extends RPGAbility;

var config float HealthBonusMax;
var config int HealthBonusAbsoluteCap;

var config bool bAllowForVehicles;

var localized string AbsoluteCapText;

replication
{
	reliable if(Role == ROLE_Authority)
		HealthBonusMax, HealthBonusAbsoluteCap;
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Pawn HealMe;
	local int Health, HealthBonus;

	if(Injured == InstigatedBy || DamageType == class'DamTypeRetaliation')
		return;
	
	if(!bAllowForVehicles && InstigatedBy.IsA('Vehicle'))
		return;

	if(Injured.IsA('Vehicle') && Vehicle(Injured).IsVehicleEmpty())
		return;

	Health = Max(Min(Injured.Health, int(float(Damage) * BonusPerLevel * float(AbilityLevel))), 0);
	if(Health == 0 && Damage > 0)
	{
		Health = 1;
	}
	if(InstigatedBy.Controller != None)
	{
		//now works in vehicle side turrets!
		if(ONSWeaponPawn(InstigatedBy) != None)
			HealMe = ONSWeaponPawn(InstigatedBy).VehicleBase;
		else
			HealMe = InstigatedBy;
	
		if(HealMe != None)
		{
			HealthBonus = HealMe.HealthMax * HealthBonusMax;
			
			if(HealthBonusAbsoluteCap > 0)
				HealthBonus = Min(HealthBonus, HealthBonusAbsoluteCap);

			HealMe.GiveHealth(Health, HealMe.HealthMax + HealthBonus);
		}
	}
}

simulated function string DescriptionText()
{
	local string Text;

	Text = repl(
		repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
		"$2", class'Util'.static.FormatPercent(HealthBonusMax));
		
	if(HealthBonusAbsoluteCap > 0)
		Text = repl(Text, "$3", repl(AbsoluteCapText, "$4", HealthBonusAbsoluteCap));
	else
		Text = repl(Text, "$3", "");
		
	return Text;
}

defaultproperties
{
	AbilityName="Vampirism"
	Description="Whenever you damage an opponent, you are healed for $1 of the damage per level (up to your starting health amount + $2$3). You can't gain health from self-damage."
	AbsoluteCapText=" or maximally +$4"
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=10
	BonusPerLevel=0.05
	HealthBonusMax=0.333333
	HealthBonusAbsoluteCap=0
	bAllowForVehicles=True
	Category=class'AbilityCategory_Health'
}
