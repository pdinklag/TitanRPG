/*
	TitanRPG Sanctuary \o/
*/
class SanctuaryGame extends xTeamGame
	config;

event InitGame(string Options, out string Error)
{
	Super.InitGame(Options, Error);
	
	AddMutator("<? echo($packageName); ?>.MutTitanRPG"); //anything else wouldn't make sense...
}

event PreBeginPlay()
{
	Super.PreBeginPlay();

	GameReplicationInfo.bNoTeamSkins = true;
	GameReplicationInfo.bForceNoPlayerLights = true;
	GameReplicationInfo.bNoTeamChanges = true;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	TriggerEvent('CreatureFactory', Self, None); //trigger all OSMT creature factories
}

function UnrealTeamInfo GetBotTeam(optional int TeamBots)
{
	return Teams[0];
}

function byte PickTeam(byte num, Controller C)
{
	return 0;
}

function GetServerInfo( out ServerResponseLine ServerState)
{
	Super.GetServerInfo(ServerState);
	ServerState.GameType = "ONSOnslaughtGame";
}

defaultproperties
{
	GoalScore=0
	TimeLimit=0

	GameName="Sanctuary"
	Description="Do whatever you like!"

	Acronym="RPG"
   	MapPrefix="RPG"

	bAllowVehicles=True
	bAllowTrans=True

	PlayerControllerClassName="<? echo($packageName); ?>.TitanPlayerController"

	ScreenShotName="UT2004Thumbnails.InvasionShots"

    TeamAIType(0)=class'InvasionTeamAI'
    TeamAIType(1)=class'InvasionTeamAI'

    EndGameSoundName(0)=You_Have_Won_the_Match
    EndGameSoundName(1)=You_Have_Lost_the_Match

	//LoginMenuClass="GUI2K4.UT2K4InvasionLoginMenu"

	HUDType="<? echo($packageName); ?>.SanctuaryHUD"
	ScoreboardType="<? echo($packageName); ?>.SanctuaryScoreboard"
	MapListType="<? echo($packageName); ?>.SanctuaryMapList"
	MutatorClass="<? echo($packageName); ?>.SanctuaryMutator"
}
