class Ability_ComboSuperSpeed extends RPGAbility;

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
			if(
				x.ComboList[i] == class'ComboSpeed' ||
				x.ComboList[i] == class'RPGComboSpeed'
			)
			{
				x.ComboList[i] = class'ComboSuperSpeed';
				break;
			}
		}
	}
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(class'ComboSuperSpeed'.default.SpeedBonus));
}

defaultproperties
{
	AbilityName="Super Speed"
	Description="Replaces the Speed adrenaline combo by Super Speed, which makes you $1 faster and has a multi-colored trail."
	MaxLevel=1
	StartingCost=40
	Category=class'AbilityCategory_Movement';
}
