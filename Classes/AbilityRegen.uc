class AbilityRegen extends RPGAbility;

var config float RegenInterval;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	SetTimer(RegenInterval, true);
}

function Timer()
{
	if(Instigator == None || Instigator.Health <= 0)
	{
		SetTimer(0.0f, false);
		return;
	}
	
	Instigator.GiveHealth(int(BonusPerLevel) * AbilityLevel, Instigator.HealthMax);
}

//TODO: Dynamic description

defaultproperties
{
	BonusPerLevel=1
	RegenInterval=1.000000

	AbilityName="Regeneration"
	Description="Heals 1 health per second per level.|Does not heal past starting health amount."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=6
	RequiredAbilities(0)=(AbilityClass=class'AbilityHealthBonus',Level=1)
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityAdrenalineRegen',Level=1)
	Category=class'AbilityCategory_Health'
}
