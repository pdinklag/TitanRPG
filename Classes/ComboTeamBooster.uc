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
		if(C.bIsPlayer && C.SameTeamAs(P.Controller) && C.Pawn != None)
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
			Other = None; //do not boost players inside of vehicles!
			//Other = Vehicle(Other).Driver;

		Pawns[i] = Other;
		
		if(Other != None)
			Effects[i] = Spawn(class'FX_TeamBooster', Other,, Other.Location, Other.Rotation);
	
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
					Other = None; //don't boost people in vehicles
					//Other = Vehicle(Other).Driver;
			
				if(Other != Pawns[i]) //respawned or entered vehicle
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
						Effects[i] = Spawn(class'FX_TeamBooster', Other,, Other.Location, Other.Rotation);
				
					if(ProcessPawn(Other))
						n++;
				}
			}
		}
	}
	
	if(n > 0 && RPRI != None)
		RPRI.AwardExperience(float(n) * class'RPGRules'.default.EXP_TeamBooster);
}

function bool ProcessPawn(Pawn P)
{
	if(P.Health < P.SuperHealthMax)
	{
		P.GiveHealth(5, P.SuperHealthMax);
		return true;
	}
	else if(P.IsA('xPawn') && xPawn(P).ShieldStrength < xPawn(P).ShieldStrengthMax)
	{
		P.AddShieldStrength(5);
		return true;
	}
	
	return false;
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
	Pawns.Length = 0;
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
