class RPGFlagObserver extends RPGGameObjectObserver;

var int OwnerTeam;

var vector DropLocation;

var float MaxReturnDist;

event Tick(float dt)
{
	Super.Tick(dt);

	if(CurrentState == 'Dropped')
		DropLocation = GO.Location;
}

function Returned()
{
	local float ClosestDist, Dist;
	local Controller Closest, C;
	local RPGPlayerReplicationInfo RPRI;
	local CTFBase FlagBase, ClosestBase;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if(C.GetTeamNum() == OwnerTeam && C.Pawn != None)
		{
			Dist = VSize(C.Pawn.Location - DropLocation);
			if(Dist < MaxReturnDist && (Dist < ClosestDist || Closest == None))
			{
				Closest = C;
				ClosestDist = Dist;
			}
		}
	}
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Closest);
	if(RPRI != None)
	{
		Log(GO @ "was returned by" @ RPRI.RPGName);
		
		//Find closest CTF base
		foreach AllActors(class'CTFBase', FlagBase)
		{
			Dist = VSize(FlagBase.Location - DropLocation);
			if(Dist < ClosestDist || ClosestBase == None)
			{
				ClosestDist = Dist;
				ClosestBase = FlagBase;
			}
		}
		
		if(ClosestBase != None)
		{
			if(ClosestBase.DefenderTeamIndex == OwnerTeam)
			{
				//return near friendly base
				if(ClosestDist > 1024)
					RPRI.AwardExperience(Rules.EXP_ReturnFriendlyFlag);
			}
			else
			{
				if(ClosestDist <= 1024)
					RPRI.AwardExperience(Rules.EXP_FlagDenial); //DENIED
				else
					RPRI.AwardExperience(Rules.EXP_ReturnEnemyFlag); //near enemy base
			}
		}
		else
		{
			//Seriously, wtf?
			Warn("A flag was returned, but there are no flag bases!");
		}
	}
}

function Scored(float ScoreDiff)
{
	local int i;
	local RPGPlayerReplicationInfo RPRI;
    local TransLauncher TL;
    
    //Return translocator beacon to scorer
    TL = TransLauncher(Holder.Pawn.FindInventoryType(class'TransLauncher'));
    if(TL != None)
    {
        if(TL.TransBeacon != None && !TL.TransBeacon.Disrupted())
        {
            TL.TransBeacon.bNoAI = true;
            TL.TransBeacon.Destroy();
            TL.TransBeacon = None;
        }
    }
	
	//XP for scorer
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Holder);
	if(RPRI != None)
		RPRI.AwardExperience(Rules.EXP_FlagCapFinal);

	//XP for first touch
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(FirstTouch);
	if(RPRI != None)
		RPRI.AwardExperience(Rules.EXP_FlagCapFirstTouch);
	
	//XP for assists
	for(i = 0; i < Assists.Length; i++)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Assists[i].Assist);
		if(RPRI != None)
		{
			if(Assists[i].bHeld)
			{
				//actually held the flag
				RPRI.AwardExperience(Rules.EXP_FlagCapAssist);
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
	GO = CTFBase(Objective).myFlag;
	
	if(GO != None)
		OwnerTeam = CTFFlag(GO).TeamNum;
}

defaultproperties
{
	MaxReturnDist=64.0f
}
