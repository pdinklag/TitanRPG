class RPGTotem extends ASVehicle abstract placeable
    config(TitanRPG);

var config int Strength;
var config float Radius;

var class<RPGTotemIcon> IconClass;

var Material TeamSkins[4];
var Material DeadSkin;

var float IconOffZ;
var vector IconLocation;
var RPGTotemIcon Icon;

var array<RPGTotemWall> Walls;
var config bool bEnableWalls;
var config float WallDistMin, WallDistMax, WallDistMaxZ;

replication {
    reliable if(Role == ROLE_Authority && bNetDirty)
        Icon;
}

simulated event PreBeginPlay() {
    Super.PreBeginPlay();
    
    if(Role == ROLE_Authority) {
        Health = Strength;
        HealthMax = Strength;
        SightRadius = Radius;
    }
}

simulated event PostBeginPlay() {
    Super.PostBeginPlay();
    
    IconLocation = Location + IconOffZ * vect(0, 0, 1);
    if(Role == ROLE_Authority && IconClass != None) {
        Icon = Spawn(IconClass, Self,, IconLocation);
    }
}

function SetMaster(Controller Master);

function SetTeamNum(byte TeamNum) {
    local int x;
    local RPGTotem T;
    local RPGTotemWall Wall;
    
    Super.SetTeamNum(TeamNum);

    for(x = 0; x < Walls.Length; x++) {
        if(Walls[x] != None) {
            Walls[x].Destroy();
        }
    }
    Walls.Length = 0;
    
    if(bEnableWalls) {
        foreach VisibleCollidingActors(class'RPGTotem', T, WallDistMax) {
            if(T != Self && T.Team == Team && VSize(Location - T.Location) >= WallDistMin && Abs(Location.Z - T.Location.Z) <= WallDistMaxZ) {
                Wall = Spawn(class'RPGTotemWall');
                Wall.Connect(Self, T);
            }
        }
    }
}

simulated event TeamChanged() {
    local int i;
    
    if(Team >= 0 && Team <= 3) {
        i = Team;
    } else {
        i = 0;
    }
    
    Skins[0] = TeamSkins[i];
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation) {
    local Controller C;   
    
    Skins[0] = DeadSkin;
    RepSkin = DeadSkin;
    
    if(Controller != None) {
        C = Controller;
        C.WasKilledBy(Killer);
        Level.Game.Killed(Killer, C, self, damageType);
        C.Destroy();
    }

	if(Killer != None) {
		TriggerEvent(Event, Self, Killer.Pawn);
	} else {
		TriggerEvent(Event, Self, None);
    }
    
    if(Icon != None) {
        Icon.Destroy();
    }
    
    DestroyWalls();
    
    PlayDying(DamageType, HitLocation);
    ClientDying(DamageType, HitLocation);
    
    GotoState('Dying');
}

function AddDefaultInventory() {
    //None
}

function DestroyWalls() {
    local array<RPGTotem> AffectedTotems;
    local int x;
    
    AffectedTotems[0] = Self;
    for(x = 0; x < Walls.Length; x++) {
        if(Walls[x] != None) {
            if(Walls[x].Totems[0] != Self) {
                AffectedTotems[AffectedTotems.Length] = Walls[x].Totems[0];
            }
            
            if(Walls[x].Totems[1] != Self) {
                AffectedTotems[AffectedTotems.Length] = Walls[x].Totems[1];
            }
            
            Walls[x].Destroy();
        }
    }
    
    for(x = 0; x < AffectedTotems.Length; x++) {
        AffectedTotems[x].CheckWalls();
    }
}

function CheckWalls() {
    local int x;
    
    while(x < Walls.Length) {
        if(Walls[x] == None || Walls[x].bPendingDelete) {
            Walls.Remove(x, 1);
        } else {
            x++;
        }
    }
}

function bool ConnectedToWall(RPGTotemWall W) {
    local int x;
    
    for(x = 0; x < Walls.Length; x++) {
        if(Walls[x] == W) {
            return true;
        }
    }
    
    return false;
}

simulated event Destroyed() {
    DestroyWalls();
    
    if(Icon != None) {
        Icon.Destroy();
    }
    
    Super.Destroyed();
}

defaultproperties {
    //Config
	Radius=1024
    Strength=500
    
    bEnableWalls=True
    
    WallDistMin=256
    WallDistMax=768
    WallDistMaxZ=96
    
    IconOffZ=96
    
    //Custom
    Physics=PHYS_None
    
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'TitanRPG.Totem.Totem'

    TeamSkins[0]=None //original is red
    TeamSkins[1]=Shader'TitanRPG.Totem.BlueShader'
    TeamSkins[2]=Shader'TitanRPG.Totem.GreenShader'
    TeamSkins[3]=Shader'TitanRPG.Totem.GoldShader'
    DeadSkin=Shader'cp_Evilmetal.plainmetal.cp_plainmet4_Shiny'
    
	bAutoTurret=true
	AutoTurretControllerClass=class'RPGTotemController'
    
    //From ASVehicle_Sentinel
	TransientSoundVolume=0.75
	TransientSoundRadius=512
	bNetNotify=true

	bSimulateGravity=false
	AirSpeed=0.0
	WaterSpeed=0.0
	AccelRate=0.0
	JumpZ=0.0
	MaxFallSpeed=0.0

	bIgnoreEncroachers=true
    bCollideWorld=false
    
	bIgnoreForces=true
	bShouldBaseAtStartup=false
	bNonHumanControl=true
	bDefensive=true
	bStationary=true
	VehicleNameString="Totem"
    
    bNoTeamBeacon=true

    //From ASTurret
	bPathColliding=true
    
    RemoteRole=ROLE_SimulatedProxy
    
	bSpecialCalcView=true
	bSpecialHUD=true

	FPCamPos=(X=0,Y=0,Z=40)
    
    AmbientGlow=64

	bUseCylinderCollision=false
    
    bRemoteControlled=true
    bDesiredBehindView=false
}
