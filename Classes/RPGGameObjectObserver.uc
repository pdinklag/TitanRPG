/*
	Observes a game object.
*/
class RPGGameObjectObserver extends Info;

var RPGRules Rules;
var array<TeamInfo> Teams;

var GameObject GO;

var name CurrentState; //state of the object

var Controller Holder; //last holder
var int HoldingTeam; //team of last holder
var float HoldingTeamScore; //score of last team

var float DropTime;

var Controller FirstTouch; //first holder of current cap

struct AssistStruct
{
	var Controller Assist;
	var float Time;
	var bool bHeld; //actually held the object
};
var array<AssistStruct> Assists;

var float TotalTimeHeld;

static function RPGGameObjectObserver GetFor(GameObject GO)
{
	local RPGGameObjectObserver Observer;
	
	foreach GO.DynamicActors(class'RPGGameObjectObserver', Observer)
	{
		if(Observer.GO == GO)
			return Observer;
	}
	
	return None;
}

function IncreaseAssistTime(Controller Assist, float dt, optional bool bIsHolder)
{
	local AssistStruct NewAssist;
	local int i;
	
	for(i = 0; i < Assists.Length; i++)
	{
		if(Assists[i].Assist == Assist)
		{
			Assists[i].Time += dt;
			Assists[i].bHeld = Assists[i].bHeld || bIsHolder;
			return;
		}
	}
	
	NewAssist.Assist = Assist;
	NewAssist.Time = dt;
	NewAssist.bHeld = bIsHolder;
	
	Assists[Assists.Length] = NewAssist;
}

event PostBeginPlay()
{
	local TeamInfo Team;

	Super.PostBeginPlay();
	
	GO = GameObject(Owner);
	if(GO == None)
		Destroy();

	Rules = class'RPGRules'.static.Instance(Level);

	//Find teams
	if(Level.Game.bTeamGame)
	{
		foreach DynamicActors(class'TeamInfo', Team)
			Teams[Team.TeamIndex] = Team;
	}

	CurrentState = GO.GetStateName();
}

event Tick(float dt)
{
	local byte NewTeam;
	local ONSVehicle AssistVehicle;
	local name LastState;
	local array<Controller> AssistPassengers;
	local int i;

	if(GO == None)
	{
		Destroy();
		return;
	}
	
	LastState = CurrentState;
	CurrentState = GO.GetStateName();
	
	if(CurrentState == 'Held')
	{
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

function AssistMessage(Controller C)
{
	if(C != Holder && C.IsA('PlayerController'))
		PlayerController(C).ReceiveLocalizedMessage(class'RPGAssistLocalMessage');
}

//abstract
function Returned();
function Scored(float ScoreDiff);

defaultproperties
{
}
