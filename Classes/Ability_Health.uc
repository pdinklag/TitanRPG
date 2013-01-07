class Ability_Health extends RPGAbility;

var bool bSuicided;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	if(!bSuicided)
		Other.Health = Other.default.Health + AbilityLevel * int(BonusPerLevel);
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
	AbilityName="Health"
	StatName="Health Bonus"
	Description="Increases your starting health by $1 per level, unless you killed yourself previously. Your maximum health is not affected by this ability."
	MaxLevel=3
	StartingCost=5
	BonusPerLevel=10
	Category=class'AbilityCategory_Health'
}
