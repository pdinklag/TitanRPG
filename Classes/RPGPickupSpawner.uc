//Spawns pickups at random path nodes.
class RPGPickupSpawner extends Info
    config(TitanRPG);

var config int SpawnDelay; //spawn a pickup every this many seconds - zero disables

var config int AdreanlineSpawnAmount;
var config int MaxAdrenalinePickups;
var array<AdrenalinePickup> CurrentAdrenPickups;

var config int MaxPickups;

struct PickupChance {
    var class<Pickup> PickupClass;
    var int Chance;
};

var config array<PickupChance> AvailablePickups;
var int TotalPickupChance; // precalculated total Chance of all pickups
var array<Pickup> CurrentPickups;

var config float PickupLifetime;
var config StaticMesh PickupStatic;
var config float PickupDrawScale;

var array<PathNode> PathNodes;

var MutTitanRPG RPGMut;
var bool bAdrenaline, bPickups;

event PostBeginPlay() {
    local class<RPGArtifactPickup> ArtifactPickupClass;
    local AdrenalinePickup AdrenPickup;
    local NavigationPoint N;
    local int x;

    Super.PostBeginPlay();
    
    RPGMut = MutTitanRPG(Owner);

    //Validate pickups
    x = 0;
    while(x < AvailablePickups.Length) {
        if(AvailablePickups[x].PickupClass == None) {
            AvailablePickups.Remove(x, 1);
        } else {
            ArtifactPickupClass = class<RPGArtifactPickup>(AvailablePickups[x].PickupClass);
            if(
                ArtifactPickupClass != None &&
                    (!RPGMut.GameSettings.bAllowArtifacts ||
                    !RPGMut.GameSettings.AllowArtifact(class<RPGArtifact>(ArtifactPickupClass.default.InventoryType)))
            ) {
                AvailablePickups.Remove(x, 1);
            } else {
                x++;
            }
        }
    }

    if(AdreanlineSpawnAmount > 0) {
        //Count how many adrenaline pickups are already on the map
        x = 0;
        foreach AllActors(class'AdrenalinePickup', AdrenPickup) {
            x++;
        }

        //Only spawn as many as required to achieve the spawn amount
        MaxAdrenalinePickups = Max(0, MaxAdrenalinePickups - x);

        Log("Found " $ x $ " adrenaline pickups on the map, set MaxAdrenalinePickups to " $ MaxAdrenalinePickups, 'TitanRPG');
    }

    bPickups = (SpawnDelay > 0 && MaxPickups > 0 && AvailablePickups.Length > 0);
    bAdrenaline = (SpawnDelay > 0 && AdreanlineSpawnAmount > 0);

    if(bPickups || bAdrenaline) {
        for(N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint) {
            if (PathNode(N) != None && !N.IsA('FlyingPathNode')) {
                PathNodes[PathNodes.length] = PathNode(N);
            }
        }

        if(PathNodes.Length == 0) {
            Warn("No eligible path nodes have been found - artifact / adrenaline spwaning disabled!");
            Destroy();
            return;
        }

        if(bPickups) {
            for(x = 0; x < AvailablePickups.length; x++) {
                TotalPickupChance += AvailablePickups[x].Chance;
            }
        }

        SetTimer(SpawnDelay, true);
    } else {
        Destroy();
    }
}

function Timer() {
    local int x;

    //Adrenaline
    if(bAdrenaline) {
        for (x = 0; x < CurrentAdrenPickups.length; x++)  {
            if (CurrentAdrenPickups[x] == None) {
                CurrentAdrenPickups.Remove(x, 1);
                x--;
            }
        }
        
        for(x = 0; CurrentAdrenPickups.length < MaxAdrenalinePickups && x < AdreanlineSpawnAmount; x++) {
            SpawnAdrenaline();
        }
    }

    //Pickups
    if(bPickups) {
        for (x = 0; x < CurrentPickups.length; x++) {
            if (CurrentPickups[x] == None) {
                CurrentPickups.Remove(x, 1);
                x--;
            }
        }

        if(CurrentPickups.length < MaxPickups) {
            SpawnRandomPickup();
        }
    }
}

function PathNode FindSpawnLocation(class<Actor> ForWhat) {
    local PathNode PathNode;
    local Pickup Pickup;
    local int i;
    local bool bAlreadyUsed;

    for(i = 0; i < 20; i++) {
        PathNode = PathNodes[Rand(PathNodes.Length)];

        //check whether there's already a pickup here
        bAlreadyUsed = false;
        foreach PathNode.VisibleCollidingActors(class'Pickup', Pickup, ForWhat.default.CollisionRadius) {
            bAlreadyUsed = true;
        }

        if(!bAlreadyUsed) {
            return PathNode;
        }
    }
    return None;
}

function SpawnAdrenaline() {
    local PathNode PathNode;
    local AdrenalinePickup APickup;

    PathNode = FindSpawnLocation(class'XPickups.AdrenalinePickup');
    if(PathNode != None) {
        APickup = spawn(class'XPickups.AdrenalinePickup', , , PathNode.Location);
        
        if (APickup == None) {
            return;
        }

        APickup.RespawnEffect();
        APickup.RespawnTime = 0.0;
        APickup.AddToNavigation();
        CurrentAdrenPickups[CurrentAdrenPickups.length] = APickup;
    }
}

function int GetRandomPickupIndex() {
    local int i;
    local int Chance;

    Chance = Rand(TotalPickupChance);
    for (i = 0; i < AvailablePickups.Length; i++) {
        Chance -= AvailablePickups[i].Chance;
        if (Chance < 0) {
            return i;
        }
    }
}

function SpawnRandomPickup() {
    local Sync_SpawnedPickup Sync;
    local int Index;
    local PathNode PathNode;
    local Pickup APickup;

    Index = GetRandomPickupIndex();

    PathNode = FindSpawnLocation(AvailablePickups[Index].PickupClass);
    if(PathNode != None) {
        APickup = Spawn(AvailablePickups[Index].PickupClass, Self,, PathNode.Location);
        if (APickup != None) {
            if(PickupStatic != None) {
                Sync = class'Sync_SpawnedPickup'.static.Sync(APickup, PickupStatic, PickupDrawScale);
                Sync.LifeSpan = PickupLifetime * 2.0;
            }
            
            APickup.RespawnEffect();
            APickup.RespawnTime = 0.0;
            APickup.AddToNavigation();
            APickup.bDropped = True;
            APickup.SetTimer(PickupLifetime, false);
            
            CurrentPickups[CurrentPickups.length] = APickup;
        }
    }
}

defaultproperties {
    SpawnDelay=15
    MaxPickups=25
    AdreanlineSpawnAmount=5
    MaxAdrenalinePickups=25
    
    PickupLifetime=30
    PickupStatic=None
    PickupDrawScale=1
}
