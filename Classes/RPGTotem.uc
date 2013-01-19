class RPGTotem extends Actor
    placeable;

var int TeamNum;
var float Radius, Interval;

var bool bHasInstigator;
var int Health;

//Looks
var float IndicatorZOffset;
var vector IndicatorLocation;

var StaticMesh IndicatorStaticMesh;
var float IndicatorDrawScale;

var RPGTotemIndicator Indicator;

var Material TeamSkins[4];

simulated event PostBeginPlay() {
    Super.PostBeginPlay();
    //TODO spawn effect
    
    if(Role == ROLE_Authority){
        //Spawn indicator
        IndicatorLocation = Location + (CollisionHeight + IndicatorZOffset) * vect(0, 0, 1);
        Indicator = Spawn(class'RPGTotemIndicator', Self,, IndicatorLocation);
        Indicator.SetStaticMesh(IndicatorStaticMesh);
        Indicator.SetDrawScale(IndicatorDrawScale);
    
        //Set skin
        bHasInstigator = (Instigator != None);
        
        Log("RPGTotem: Instigator =" @ Instigator);
        if(Instigator != None && Instigator.Controller != None) {
            TeamNum = Instigator.Controller.GetTeamNum();
            if(TeamNum >= 0 && TeamNum <= 3) {
                Skins[0] = TeamSkins[TeamNum];
                RepSkin = TeamSkins[TeamNum];
            }
        }

        //Set interval timer
        SetTimer(Interval, true);
    }
}

event Tick(float dt) {
    super.Tick(dt);

    if(bHasInstigator) {
        if(Instigator == None || Instigator.Health <= 0) {
            Destroy(); //destroy when owner dies
        }
    }
}

event TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType) {
    if(InstigatedBy == None || !SameTeamAs(InstigatedBy.Controller)) {
        Health = Max(0, Health - Damage);
        if(Health == 0) {
            //TODO explosion
            Destroy();
        }
    }
}

simulated event Destroyed() {
    Super.Destroyed();
    
    if(Indicator != None) {
        Indicator.Destroy();
    }
}

function bool SameTeamAs(Controller C) {
    local int CTeam;
    
    if(C == None) {
        return false;
    }
    
    CTeam = C.GetTeamNum();
    return (TeamNum != 255 && CTeam != 255 && TeamNum == CTeam);
}

function Timer() {
    local Actor A;

    foreach VisibleCollidingActors(class'Actor', A, Radius) {
        DoEffect(A);
    }
}

//Impose effect on actor
function DoEffect(Actor Other);

defaultproperties {
    Radius=1024
    Interval=1.0
    
    Health=100

    bReplicateInstigator=True
    bAlwaysRelevant=True
    NetUpdateFrequency=1
    RemoteRole=ROLE_SimulatedProxy

    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'TitanRPG.Totem.TotemStatic'
    
    bCollideActors=True
    bBlockActors=True
    bBlockPlayers=True
    bBlockProjectiles=True
    bProjTarget=True
    bUseCylinderCollision=False
    bBlockZeroExtentTraces=True
    bBlockNonZeroExtentTraces=True
    bBlockKarma=True
    
    CollisionHeight=132 //used for stuff
    IndicatorZOffset=32
    
    IndicatorStaticMesh=StaticMesh'E_Pickups.Health.MidHealth'
    IndicatorDrawScale=0.33
    
    TeamSkins[0]=None //original is red
    TeamSkins[1]=Shader'TitanRPG.Totem.BlueShader'
    TeamSkins[2]=Shader'TitanRPG.Totem.GreenShader'
    TeamSkins[3]=Shader'TitanRPG.Totem.GoldShader'
}
