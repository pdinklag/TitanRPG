class Ability_ComboTeamBooster extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReplaceCombo;
}

simulated function ClientReplaceCombo()
{
	ReplaceCombo(xPlayer(RPRI.Controller));
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	
	ReplaceCombo(xPlayer(RPRI.Controller));
	ClientReplaceCombo();
}

simulated function ReplaceCombo(xPlayer x)
{
	local int i;
	
	if(x != None)
	{
		for(i = 0; i < 16; i++)
		{
			if(x.ComboList[i] == class'ComboDefensive')
			{
				x.ComboList[i] = class'ComboTeamBooster';
				break;
			}
		}
	}
}

defaultproperties
{
	AbilityName="Team Booster"
	Description="Replaces the Booster adrenaline combo by Team Booster, which will heal everyone on your team instead of just yourself and award experience for it."
	MaxLevel=1
	StartingCost=20
	RequiredAbilities(0)=(AbilityClass=class'Ability_Medic',Level=1)
	Category=class'AbilityCategory_Medic'
}
