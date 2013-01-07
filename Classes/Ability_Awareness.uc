class Ability_Awareness extends RPGAbility;

//client
var AwarenessInteraction Interaction;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientCreateInteraction;
}

simulated function ClientCreateInteraction()
{
	local PlayerController PC;

	if(Interaction == None)
	{
		PC = Level.GetLocalPlayerController();
		if(PC == None)
			return;

		Interaction = AwarenessInteraction(
			PC.Player.InteractionMaster.AddInteraction(
				"TitanRPG.AwarenessInteraction", PC.Player));
	}
	
	if(Interaction != None)
		Interaction.AbilityLevel = AbilityLevel;
}

simulated event Destroyed()
{
	if(Interaction != None)
		Interaction.Remove();
	
	Interaction = None;
	Super.Destroyed();
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	if(Role == ROLE_Authority)
		ClientCreateInteraction();
}

defaultproperties
{
	AbilityName="Awareness"
	Description="Informs you of your enemies' health with a display over their heads."
	LevelDescription(0)="At level 1 you get a colored indicator (green, yellow, or red)."
	LevelDescription(1)="At level 2 you get a colored health bar and a shield bar."
	StartingCost=20
	CostAddPerLevel=5
	MaxLevel=2
	Category=class'AbilityCategory_Misc'
}
