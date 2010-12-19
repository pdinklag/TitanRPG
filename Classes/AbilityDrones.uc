class AbilityDrones extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientAddCombo;
}

function ModifyRPRI()
{
	RPRI.MaxDrones += AbilityLevel;
}

simulated function ClientAddCombo()
{
	AddCombo(xPlayer(RPRI.Controller));
}

function ModifyPawn(Pawn Other)
{
	local int x;

	Super.ModifyPawn(Other);

	if(Role == ROLE_Authority)
	{
		for(x = 0; x < AbilityLevel; x++)
			class'Drone'.static.SpawnFor(Other);
	}

	AddCombo(xPlayer(RPRI.Controller));
	ClientAddCombo();
}

simulated function AddCombo(xPlayer Player)
{
	local int x;

	if(Player != None)
	{
		for(x = 0; x < 16; x++)
		{
			if(Player.ComboList[x] == None)
			{
				Player.ComboList[x] = class'ComboDrone';
				break;
			}
		}
	}
}

defaultproperties
{
	AbilityName="Drones"
	Description="When you spawn, per level, one additional drone gets spawned which heals you and attacks enemies."
	StartingCost=10
	MaxLevel=5
}
