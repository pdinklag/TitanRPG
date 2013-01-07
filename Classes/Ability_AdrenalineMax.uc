class Ability_AdrenalineMax extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientSetAdrenalineMax;
}

simulated function ClientSetAdrenalineMax(Controller C, int Max)
{
	C.AdrenalineMax = Max;
}

function ModifyPawn(Pawn P)
{
	Super.ModifyPawn(P);

	RPRI.Controller.AdrenalineMax = 100 + AbilityLevel * int(BonusPerLevel);
	
	if(Level.NetMode == NM_DedicatedServer)
		ClientSetAdrenalineMax(RPRI.Controller, RPRI.Controller.AdrenalineMax);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", int(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Adrenaline Container"
	StatName="Max Adrenaline Bonus"
	Description="Increases your maximum adrenaline amount by $1 per level.|Combos can still be activated with 100 adrenaline."
	MaxLevel=10
	StartingCost=5
	BonusPerLevel=5
	Category=class'AbilityCategory_Adrenaline'
}
