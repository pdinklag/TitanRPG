class Ability_AdrenalineRegen extends RPGAbility;

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	SetTimer((MaxLevel - AbilityLevel) + 1, true);
}

function Timer()
{
	if(Instigator == None || Instigator.Health <= 0)
	{
		SetTimer(0.0f, false);
		return;
	}

	if(!Instigator.InCurrentCombo() &&
		!class'RPGArtifact'.static.HasActiveArtifact(Instigator))
	{
		RPRI.Controller.AwardAdrenaline(BonusPerLevel); //BonusPerLevel is a constant
	}
}

defaultproperties
{
	BonusPerLevel=1
	AbilityName="Adrenal Drip"
	Description="Slowly drips adrenaline into your system."
	LevelDescription(0)="At level 1 you get one adrenaline every 3 seconds."
	LevelDescription(1)="At level 2 you get one adrenaline every 2 seconds."
	LevelDescription(2)="At level 3 you get one adrenaline every second."
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=3
	Category=class'AbilityCategory_Adrenaline'
}
