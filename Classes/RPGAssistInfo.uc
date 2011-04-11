//============================================================================
// RPGAssistInfo
// Copyright 2007 by Jrubzjeknf <rrvanolst@hotmail.com>
//
// Monitors the flags and checks how long a flag carrier has been sitting on a
// manta. When the flag is capped, the manta driver is rewarded for his share
// in the cap.
//
// merged into TitanRPG 1.30 by pd
//
/*
	(TitanRPG 1.35)

	This has been updated to not only process manta runs but
	teamwork captures in general.

	There are not only Mantaruns.
	People can stand on other vehicles besides Mantas, like Scorpions.
	
	Caps with vehicles with multiple passengers (e.g. HellBender) should
	also be considered, after all the passengers are assisting the carrier.
	
	-pd
*/
// ============================================================================

class RPGAssistInfo extends ReplicationInfo
	config(TitanRPG);

//============================================================================
// Variables
//============================================================================

var config int MaxAssistAdrenaline;

var TeamInfo EnemyTeamInfo;
var float EnemyTeamScore;

var float TimeCarryingFlag;
var float FlagTakenTime;

struct FlagCapturePoints
{
	var Controller Helper;
	var float TimeHelped;
};

var array<FlagCapturePoints> FlagCapturePointsArray;


//============================================================================
// PostBeginPlay
//
// Initiates flag monitoring.
//============================================================================

function PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTimer(1, true);
}


//============================================================================
// Timer
//
// Checks if the flag carrier is sitting on a manta. Every second he's sitting
// on one, the manta driver gets an assist second. This will be used for
// giving the manta driver points and adrenaline for the manta run.
//============================================================================

function Timer()
{
	local Controller Helper;
	local Vehicle V;
	local ONSVehicle OV;
	local ONSWeaponPawn WP;
	local int i;

	if(Owner !=	None)
	{
		if(FlagTakenTime != CTFFlag(Owner).TakenTime) //the flag has just been taken, check it the flag has been captured between seconds.
		{
			CheckCapture();
			FlagTakenTime = CTFFlag(Owner).TakenTime;
		}

		if(!Owner.IsInState('Home')) //The flag is being carried or has been dropped.
		{
			TimeCarryingFlag += 1;

			if(CTFFlag(Owner).Holder != None)
			{
				//this checks for the carrier being in a vehicle with other passengers (e.g. HellBender)
				V = CTFFlag(Owner).Holder.DrivenVehicle;
				if(V != None)
				{
					if(ONSWeaponPawn(V) != None)
						OV = ONSWeaponPawn(V).VehicleBase;
					else
						OV = ONSVehicle(V);
						
					if(OV != None)
					{
						if(OV.Driver != None && OV.Driver != CTFFlag(Owner).Holder)
							UpdateTimeHelpedFor(OV.Controller);
						
						for(i = 0; i < OV.WeaponPawns.length; i++)
						{
							WP = OV.WeaponPawns[i];
							
							if(WP.Driver != None && WP.Driver != CTFFlag(Owner).Holder)
								UpdateTimeHelpedFor(WP.Controller);
						}
					}
				}
				//this checks for the carrier being carried on top of a vehicle (e.g. Manta, Scorpion)
				else if(CTFFlag(Owner).Holder.Base != None &&
					ONSVehicle(CTFFlag(Owner).Holder.Base) != None &&
					ONSVehicle(CTFFlag(Owner).Holder.Base).Driver != None &&
					ONSVehicle(CTFFlag(Owner).Holder.Base).Driver != CTFFlag(Owner).Holder) //The flag carrier is sitting on an occupied vehicle, but not driving it.
				{
					Helper = ONSVehicle(CTFFlag(Owner).Holder.Base).Controller;
					if(Helper.GetTeamNum() == CTFFlag(Owner).Holder.GetTeamNum()) //The helper driver is friendly.
					{
						UpdateTimeHelpedFor(Helper); //Give the driver seconds.
					}
				}
			}
		}
		else if(TimeCarryingFlag != 0) //The flag is home, but has been carried. Check if the flag has been captured.
		{
			CheckCapture();
		}
	}
}


//============================================================================
// CheckCapture
//
// Check if the flag has been captured.
//============================================================================

function CheckCapture()
{
	local RPGPlayerReplicationInfo RPRI;
	local int i;
	local float RelativeTimeHelped;
	local Controller C;

	if(EnemyTeamScore != EnemyTeamInfo.Score)
	{
		EnemyTeamScore = EnemyTeamInfo.Score;

		for(i = 0; i < FlagCapturePointsArray.Length; i++)
		{
			C = FlagCapturePointsArray[i].Helper;

			if(PlayerController(C) != None)
				PlayerController(C).ReceiveLocalizedMessage(class'RPGAssistLocalMessage');

			RelativeTimeHelped = FlagCapturePointsArray[i].TimeHelped / TimeCarryingFlag;

			if(C.PlayerReplicationInfo != None)
				C.PlayerReplicationInfo.Score += RelativeTimeHelped * 15.0f;
			
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
			if(RPRI != None)
				RPRI.AwardExperience(RelativeTimeHelped * class'RPGRules'.default.EXP_Assist);
			
			C.AwardAdrenaline(RelativeTimeHelped * default.MaxAssistAdrenaline);
		}
	}

	TimeCarryingFlag = 0;
	FlagCapturePointsArray.Length = 0;
}


//============================================================================
// UpdateTimeDrivenFor: give current helper seconds.
// GetIndexOf: gets array index of current helper.
// AddToArray: add current helper to array.
//============================================================================

function UpdateTimeHelpedFor(Controller Helper)
{
	local int i;
	
	i = GetIndexOf(Helper);

	if(i != -1)
		FlagCapturePointsArray[i].TimeHelped += 1;
	else
		AddToArray(Helper);
}

function int GetIndexOf(Controller C)
{
	local int i;

	for(i=0; i < FlagCapturePointsArray.Length; i++)
	{
		if(FlagCapturePointsArray[i].Helper == C)
			return i;
	}

	return -1;
}

function AddToArray(Controller C)
{
	local int i;

	i = FlagCapturePointsArray.Length;

	FlagCapturePointsArray.Length = i + 1; //FlagCapturePointsArray.Length++; would make it crash 0_o
	FlagCapturePointsArray[i].Helper = C;
	FlagCapturePointsArray[i].TimeHelped = 1;
}

defaultproperties
{
	//original game values
	MaxAssistAdrenaline=25
}
