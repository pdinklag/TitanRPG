class RPGGameObjectObserver extends RPGGameObjectiveObserver abstract;

var GameObject GO;

var name CurrentState; //state of the object

var Controller Holder; //last holder
var int HoldingTeam; //team of last holder
var float HoldingTeamScore; //score of last team

var float DropTime;

var Controller FirstTouch; //first holder of current cap

var float TotalTimeHeld;

event Tick(float dt)
{
	local byte NewTeam;
	local ONSVehicle AssistVehicle;
	local name LastState;
	local array<Controller> AssistPassengers;
	local int i;
	
	Super.Tick(dt);
	
	if(GO == None)
		SetGameObject();
	
	if(GO != None)
	{
		LastState = CurrentState;
		CurrentState = GO.GetStateName();
		
		if(CurrentState == 'Held')
		{
			if(GO.Holder.DrivenVehicle != None)
				Holder = GO.Holder.DrivenVehicle.Controller;
			else
				Holder = GO.Holder.Controller;

			NewTeam = Holder.GetTeamNum();
			if(NewTeam != HoldingTeam && LastState == 'Dropped')
			{
				//object was picked up by a different team, e.g. in CTF4
				FirstTouch = None;
				TotalTimeHeld = 0;
			}
			
			HoldingTeam = NewTeam;
			
			if(Level.Game.bTeamGame)
				HoldingTeamScore = Teams[HoldingTeam].Score;
			
			if(LastState == 'Home')
			{
				//object was picked up from its base
				FirstTouch = Holder;
				TotalTimeHeld = 0;
			}

			TotalTimeHeld += dt;
			
			//Holder assist
			IncreaseAssistTime(Holder, dt, true);

			//Find assisting vehicle (holder standing on it or sitting in it)
			AssistVehicle = ONSVehicle(GO.Holder.Base);
			if(AssistVehicle == None || AssistVehicle.Controller == None || !AssistVehicle.Controller.SameTeamAs(Holder))
			{
				AssistVehicle = ONSVehicle(GO.Holder.DrivenVehicle);
				if(AssistVehicle == None && ONSWeaponPawn(GO.Holder.DrivenVehicle) != None)
					AssistVehicle = ONSWeaponPawn(GO.Holder.DrivenVehicle).VehicleBase;
			}
			
			//Assist for all assist vehicle passengers
			if(AssistVehicle != None)
			{
				AssistPassengers = class'Util'.static.GetAllPassengerControllers(AssistVehicle);
				for(i = 0; i < AssistPassengers.Length; i++)
				{
					if(AssistPassengers[i] != Holder)
						IncreaseAssistTime(AssistPassengers[i], dt);
				}
			}
		}
		else if(CurrentState == 'Home' || CurrentState =='HomeDisabled')
		{
			if(LastState == 'Held')
			{
				if(Level.Game.bTeamGame)
				{
					if(Teams[HoldingTeam].Score > HoldingTeamScore)
						Scored(Teams[HoldingTeam].Score - HoldingTeamScore);
				}
				else
				{
					Scored(0);
				}
			}
			else if(LastState == 'Dropped')
			{
				if(Level.Game.bTeamGame && Teams[HoldingTeam].Score > HoldingTeamScore)
					Scored(Teams[HoldingTeam].Score - HoldingTeamScore); //tossed gameobject, e.g. xBombFlag
				else if(Level.TimeSeconds - DropTime < GO.MaxDropTime)
					Returned();
			}
			
			if(CurrentState != LastState)
			{
				FirstTouch = None;
				Assists.Length = 0;
				HoldingTeam = -1;
			}
		}
		else if(CurrentState == 'Dropped')
		{
			if(LastState != 'Dropped')
				DropTime = Level.TimeSeconds - dt;
		}
	}
}

function AssistMessage(Controller C)
{
	if(C != Holder)
		Super.AssistMessage(C);
}

//abstract
function Returned();
function Scored(float Score);

function SetGameObject();

defaultproperties
{
}
