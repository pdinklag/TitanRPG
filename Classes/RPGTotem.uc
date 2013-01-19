class RPGTotem extends Actor abstract
    config(TitanRPG)
    placeable;
    
#exec OBJ LOAD FILE=cp_Evilmetal.utx

var config float Radius, Interval;
var config int Health;
var config int MaxTargets;

var bool bHasInstigator;
var int TeamNum;
var class<Actor> AffectedClass;

//Looks
var float IndicatorZOffset;
var vector IndicatorLocation;

var Actor Indicator;
var class<Actor> IndicatorClass;

var Emitter ExplosionEffect;

var Material TeamSkins[4];

replication {
    unreliable if(Role == ROLE_Authority)
        ClientExplode;
}

simulated event PostBeginPlay() {
    Super.PostBeginPlay();
    //TODO spawn effect
    
    if(Role == ROLE_Authority){
        //Spawn indicator
        IndicatorLocation = Location + (CollisionHeight + IndicatorZOffset) * vect(0, 0, 1);
        if(IndicatorClass != None) {
            Indicator = Spawn(IndicatorClass, Self,, IndicatorLocation);
        }
    
        //Set skin
        bHasInstigator = (Instigator != None);

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

simulated event Destroyed() {
    Super.Destroyed();
    
    if(Indicator != None) {
        Indicator.Destroy();
    }
}

event Tick(float dt) {
    super.Tick(dt);

    if(bHasInstigator) {
        if(Instigator == None || Instigator.Health <= 0) {
            Explode();
            GotoState('Dying');
        }
    }
}

event TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType) {
    if(InstigatedBy == None || !SameTeamAs(InstigatedBy.Controller)) {
        Log("TakeDamage: " @ Damage @ InstigatedBy @ HitLocation @ Momentum @ DamageType);
        Health -= Damage;
        if(Health <= 0) {
            GotoState('Dying');
        }
    }
}

simulated event Bump(Actor Other) {
    //Make grenades stick to me
    if(Other.IsA('ONSGrenadeProjectile')) {
        Other.Touch(Self);
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

simulated function Timer() {
    if(Role == ROLE_Authority) {
        Fire();
    }
}

function Fire() {
    local Actor A;
    local int n;
    
    foreach VisibleCollidingActors(class'Actor', A, Radius, IndicatorLocation) {
        FireAt(A);
        
        n++;
        if(MaxTargets > 0 && n >= MaxTargets) {
            break;
        }
    }
}

//Impose effect on actor
function FireAt(Actor Other);

simulated function Explode() {
    if(Level.NetMode != NM_DedicatedServer) {
        Skins[0] = Shader'cp_Evilmetal.plainmetal.cp_plainmet4_Shiny';
        ExplosionEffect = Spawn(class'FX_SpaceFighter_Explosion', Self,, Location, Rotation);
        MakeNoise(1.0);
    }
}

simulated function ClientExplode() {
    GotoState('Dying');
}

state Dying {
    ignores Bump, TakeDamage;

	simulated function Timer() {
		if(!bDeleteMe) {
			Destroy();
        }
	}
    
    simulated function BeginState() {
        if(Indicator != None) {
            Indicator.Destroy();
        }
    
        if(Role == ROLE_Authority) {
            ClientExplode();
        }
    
        Explode();
        SetTimer(1.0f, false);
    }
}

defaultproperties {
    Radius=1024
    Interval=1.0
    
    Health=100
    
    MaxTargets=0 //infinite
    AffectedClass=class'Actor'
    
    IndicatorClass=class'RPGTotemIndicator'

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
    
	TransientSoundVolume=0.75
	TransientSoundRadius=512
    
    TeamSkins[0]=None //original is red
    TeamSkins[1]=Shader'TitanRPG.Totem.BlueShader'
    TeamSkins[2]=Shader'TitanRPG.Totem.GreenShader'
    TeamSkins[3]=Shader'TitanRPG.Totem.GoldShader'
}
