class AbilityAwareness extends RPGAbility;

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
				"<? echo($packageName); ?>.AwarenessInteraction", PC.Player));
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
	RequiredAbilities(0)=(AbilityClass=Class'AbilityWeaponSpeed',Level=1)
	RequiredAbilities(1)=(AbilityClass=Class'AbilityHealthBonus',Level=1)
	RequiredAbilities(2)=(AbilityClass=Class'AbilityAdrenalineMax',Level=1)
	RequiredAbilities(3)=(AbilityClass=Class'AbilityDamageBonus',Level=1)
	RequiredAbilities(4)=(AbilityClass=Class'AbilityDamageReduction',Level=1)
	RequiredAbilities(5)=(AbilityClass=Class'AbilityAmmoMax',Level=1)
}
