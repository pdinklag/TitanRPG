class Ability_Shield extends RPGAbility;

var bool bSuicided;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	if(!bSuicided)
		Other.AddShieldStrength(AbilityLevel * int(BonusPerLevel));
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	bSuicided = (Killed.Controller == Killer || Killed.Controller == None);
	
	return Super.PreventDeath(Killed, Killer, DamageType, HitLocation, bAlreadyPrevented);
}

simulated function string DescriptionText()
{
	return Repl(Super.DescriptionText(), "$1", int(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Shield"
	StatName="Shield Bonus"
	Description="You spawn with $1 shield per level, unless you killed yourself previously. Your maximum shield is not affected by this ability."
	MaxLevel=5
	StartingCost=5
	BonusPerLevel=5
	Category=class'AbilityCategory_Health'
}
