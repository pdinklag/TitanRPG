class RPGPowerCoreObserver extends RPGGameObjectiveObserver;

var ONSOnslaughtGame ONSGame;
var ONSPowerCore Core;

/**
    Stages:
        0   = Active (powered by a team)
        1   = Destroyed (only valid for final cores?)
        2   = Constructing
        3   = Reset (?)
        4   = Neutral
        5   = Reconstitution (temporary)
        255 = Disabled
*/
var int Stage;

struct RPGScorerRecord
{
	var Controller C;
    var RPGPlayerReplicationInfo RPRI;
	var float Pct;
};

var array<RPGScorerRecord> Scorers;

event PostBeginPlay() {
    Super.PostBeginPlay();
    
    ONSGame = ONSOnslaughtGame(Level.Game);
    Core = ONSPowerCore(Objective);
    Stage = Core.CoreStage;
}

event Tick(float dt) {
    local int i;
    local int LastStage;

    Super.Tick(dt);
    
    if(!ONSGame.bGameEnded && ONSGame.ResetCountDown == 0 && (Stage == 0 || Stage == 2)) {
        for(i = 0; i < Core.Scorers.Length; i++)    {
            UpdateScore(Core.Scorers[i]);
        }
    }

    //Update stage
    LastStage = Stage;
    Stage = Core.CoreStage;
    if(Stage != LastStage) {
        if(Stage == 0) {
            if(!Core.bFinalCore) {
                NodeConstructed();
            }
        }
        
        Scorers.Length = 0;
    }
}

function UpdateScore(GameObjective.ScorerRecord Score) {
    local int i;
    local float Diff, Exp;
    local RPGScorerRecord Record;
    
    for(i = 0; i < Scorers.Length; i++) {
        if(Scorers[i].C == Score.C) {
            break;
        }
    }
    
    if(i < Scorers.Length) {
        Record = Scorers[i];
        Diff = Score.Pct - Record.Pct;
    
        Record.Pct = Score.Pct;
    } else {
        Diff = Score.Pct;
    
        Record.C = Score.C;
        Record.RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Score.C);
        Record.Pct = Score.Pct;
    }
    
    if(Diff > 0) {
        //Log("Score for" @ Score.C.GetHumanReadableName() $ ": " @ Diff);
        if(Record.RPRI != None) {
            if(Core.bFinalCore) {
                //power core
                Exp = Diff * Rules.EXP_DestroyPowercore;
            } else if(Stage == 2) {
                //constructing power node
                Exp = Diff * Rules.EXP_DestroyConstructingPowernode;
            } else {
                //power node
                Exp = Diff * Rules.EXP_DestroyPowernode;
            }
            
            Rules.ShareExperience(Record.RPRI, Exp);
        }
    }
    
    Scorers[i] = Record;
}

function NodeConstructed() {
    local RPGPlayerReplicationInfo RPRI;
    
    RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Core.Constructor);
    if(RPRI != None) {
        RPRI.AwardExperience(Rules.EXP_ConstructPowernode);
    }
}

function Healed(Controller By, int Amount) {
    local RPGPlayerReplicationInfo RPRI;
    
    if(Amount > 0) {
        RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(By);
        if(RPRI != None) {
            Rules.ShareExperience(RPRI, Rules.EXP_HealPowernode * float(Amount));
        }
    }
}

defaultproperties {
}
