/*
	Observes a game objective and its game object (if any).
*/
class RPGGameObjectiveObserver extends Info;

var RPGRules Rules;
var array<TeamInfo> Teams;

//Game objective
var GameObjective Objective;

struct AssistStruct
{
	var Controller Assist;
	var float Time;
	var bool bHeld; //actually held the object
};
var array<AssistStruct> Assists;

static function RPGGameObjectiveObserver GetFor(GameObjective Objective)
{
	local RPGGameObjectiveObserver Observer;
	
	foreach Objective.AllActors(class'RPGGameObjectiveObserver', Observer)
	{
		if(Observer.Objective == Objective)
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
	Super.PostBeginPlay();
	
	Objective = GameObjective(Owner);
	if(Objective == None)
		Destroy();

	Rules = class'RPGRules'.static.Instance(Level);
}

event Tick(float dt)
{
	local TeamInfo Team;

	//Find teams
	if(Level.Game.bTeamGame && Teams.Length == 0)
	{
		foreach DynamicActors(class'TeamInfo', Team)
			Teams[Team.TeamIndex] = Team;
	}
}

function AssistMessage(Controller C)
{
	if(C.IsA('PlayerController'))
		PlayerController(C).ReceiveLocalizedMessage(class'RPGAssistLocalMessage');
}

function Healed(Controller By, int Amount);

defaultproperties
{
}
