/*
	A teleporter that will only let players with the required level or higher teleport.
*/
class LevelTeleporter extends Teleporter placeable;

var() int RequiredLevel;

simulated event PostTouch(Actor Other)
{
	local RPGPlayerReplicationInfo RPRI;
	
	if(Other.IsA('Pawn'))
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Pawn(Other).Controller);
		if(RPRI != None && RPRI.RPGLevel >= RequiredLevel)
		{
			Super.PostTouch(Other);
		}
		else
		{
			if(PlayerController(Pawn(Other).Controller) != None)
			{
				PlayerController(Pawn(Other).Controller).ReceiveLocalizedMessage(
					class'LocalMessage_LevelTeleporter', RequiredLevel);
			}
		}
	}
	else
	{
		Super.PostTouch(Other);
	}
}

defaultproperties
{
	RequiredLevel=0
}
