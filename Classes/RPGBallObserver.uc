class RPGBallObserver extends RPGGameObjectObserver;

var float HolderScore;

event Tick(float dt)
{
	Super.Tick(dt);
	
	if(CurrentState == 'Held')
		HolderScore = Holder.PlayerReplicationInfo.Score;
}

function Scored(float Score)
{
	local int i;
	local RPGPlayerReplicationInfo RPRI;
	
	//XP for scorer
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Holder);
	if(RPRI != None)
	{
		if(Score >= 7) //ball cap
			RPRI.AwardExperience(Rules.EXP_BallCapFinal);
		else //ball thrown into goal
			RPRI.AwardExperience(Rules.EXP_BallThrownFinal);
	}
	
	//XP for assists
	for(i = 0; i < Assists.Length; i++)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Assists[i].Assist);
		if(RPRI != None)
		{
			if(Assists[i].bHeld)
			{
				//actually held the ball
				RPRI.AwardExperience(Rules.EXP_BallScoreAssist);
				AssistMessage(Assists[i].Assist);
			}
			else if(Assists[i].Time > 1.0f)
			{
				//assisted with a vehicle (e.g. Mantarun)
				RPRI.AwardExperience(Rules.EXP_Assist * Assists[i].Time / TotalTimeHeld);
				AssistMessage(Assists[i].Assist);
			}
		}
	}
}

function SetGameObject()
{
	GO = xBombSpawn(Objective).myFlag;
}

defaultproperties
{
}
