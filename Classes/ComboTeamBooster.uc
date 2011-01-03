class ComboTeamBooster extends Combo;

var RPGPlayerReplicationInfo RPRI;

var array<xEmitter> Effects;
var array<Controller> Controllers;
var array<Pawn> Pawns;

function StartEffect(xPawn P)
{
	local int i;
	local Pawn Other;
	local Controller C;
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(P.Controller);
	
	//Find teammates
	i = 0;
	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if(C.SameTeamAs(P.Controller) && C.Pawn != None)
		{
			//Check whether this player has an active team booster
			Other = C.Pawn;
			if(Other.IsA('xPawn') && ComboTeamBooster(xPawn(Other).CurrentCombo) != None)
			{
				P.ReceiveLocalizedMessage(class'TeamBoosterMessage', 1, Other.PlayerReplicationInfo, , Self.class);
				
				if(P.Controller.IsA('PlayerController'))
					PlayerController(P.Controller).ClientPlaySound(Sound'WeaponSounds.BSeekLost1');
				
				Destroy();
				return;
			}
			else
			{
				Controllers[i++] = C;
			}
		}
	}
	
	//Spawn effects
	for(i = 0; i < Controllers.Length; i++)
	{
		Other = Controllers[i].Pawn;
		
		if(Other.IsA('Vehicle'))
			Other = Vehicle(Other).Driver;

		if(Other != None)
		{
			Pawns[i] = Other;
			Effects[i] = Spawn(class'TeamBoosterEffect', Other,, Other.Location, Other.Rotation);
		}
	
		//Show the message for all team members
		if(Other != None && Other != P && P.PlayerReplicationInfo != None)
			Other.ReceiveLocalizedMessage(class'TeamBoosterMessage', 0, P.PlayerReplicationInfo, , Self.class);
	}

	//Go
	SetTimer(0.9, true);
	Timer();
}

function Timer()
{	
	local Controller C;
	local Pawn Other;
	local int i, n;
	
	n = -1; //not the instigator
	for(i = 0; i < Controllers.Length; i++)
	{
		C = Controllers[i];
		if(C != None)
		{
			Other = C.Pawn;
			if(Other != None)
			{
				if(Other.IsA('Vehicle'))
					Other = Vehicle(Other).Driver;
			
				if(Other != Pawns[i]) //respawned
				{
					if(Effects[i] != None)
					{
						Effects[i].Destroy();
						Effects[i] = None;
					}
					
					Pawns[i] = Other;
				}
				
				if(Other != None)
				{
					if(Effects[i] == None)
						Effects[i] = Spawn(class'TeamBoosterEffect', Other,, Other.Location, Other.Rotation);
				
					ProcessPawn(Other);
					n++;
				}
			}
		}
	}
	
	if(n > 0 && RPRI != None)
		RPRI.AwardExperience(float(n) * class'RPGGameStats'.default.EXP_TeamBooster);
}

function ProcessPawn(Pawn P)
{
	if(P.Health < P.SuperHealthMax)
		P.GiveHealth(5, P.SuperHealthMax);
	else
		P.AddShieldStrength(5);
}

function StopEffect(xPawn P)
{
	local int i;
	
	for(i = 0; i < Effects.Length; i++)
	{
		if(Effects[i] != None)
			Effects[i].Destroy();
	}
	
	Effects.Length = 0;
	Controllers.Length = 0;
	
	SetTimer(0, false);
}

defaultproperties
{
	//Duration=20
    ExecMessage="Team Booster!"
    ComboAnnouncementName=Booster
    keys(0)=2
    keys(1)=2
    keys(2)=2
    keys(3)=2
}
