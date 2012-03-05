class FX_TeamBooster extends RegenCrosses;

var byte Team;
var Color TeamColor[4]; //OLTeamGames support

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Team;
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if(Role == ROLE_Authority && Pawn(Owner) != None)
	{
		Team = Pawn(Owner).GetTeamNum();
	}

	if(Team >= 0 && Team < 4)
	{
		mColorRange[0] = TeamColor[Team];
		mColorRange[1] = TeamColor[Team];
	}
}

defaultproperties
{
	Team=255
	Skins(0)=Texture'TitanRPG.Effects.Cross'
	TeamColor(0)=(R=255,G=0,B=0,A=255)
	TeamColor(1)=(R=0,G=0,B=255,A=255)
	TeamColor(2)=(R=0,G=255,B=0,A=255)
	TeamColor(3)=(R=255,G=224,B=0,A=255)
}
