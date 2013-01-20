//The artifact manager spawns artifacts at random PathNodes.
//It tries to make sure there's at least one artifact of every type available
class RPGArtifactManager extends Info
	config(TitanRPG);

var config int SpawnDelay; //spawn an artifact every this many seconds - zero disables

var config int MaxArtifacts;

var config int AdreanlineSpawnAmount;
var config int MaxAdrenalinePickups;
var array<AdrenalinePickup> CurrentAdrenPickups;

var config int ExperienceSpawnAmount;
var config int MaxExperiencePickups;
var array<ExperiencePickup> CurrentExperiencePickups;

struct ArtifactChance
{
	var class<RPGArtifact> ArtifactClass;
	var int Chance;
};

var config array<ArtifactChance> AvailableArtifacts;
var int TotalArtifactChance; // precalculated total Chance of all artifacts
var array<RPGArtifact> CurrentArtifacts;
var array<PathNode> PathNodes;

var bool bArtifacts;
var bool bAdrenaline;
var bool bExperience;

event PostBeginPlay()
{
	local AdrenalinePickup AdrenPickup;
	local NavigationPoint N;
	local int x;

	Super.PostBeginPlay();

	if(AdreanlineSpawnAmount > 0)
	{
		//Count how many adrenaline pickups are already on the map
		x = 0;
		foreach AllActors(class'AdrenalinePickup', AdrenPickup)
			x++;
		
		//Only spawn as many as required to achieve the spawn amount
		MaxAdrenalinePickups = Max(0, MaxAdrenalinePickups - x);
		
		Log("Found " $ x $ " adrenaline pickups on the map, set MaxAdrenalinePickups to " $ MaxAdrenalinePickups, 'TitanRPG');
	}

	bArtifacts = (SpawnDelay > 0 && MaxArtifacts > 0 && AvailableArtifacts.Length > 0);
	bAdrenaline = (SpawnDelay > 0 && AdreanlineSpawnAmount > 0);
    bExperience = (SpawnDelay > 0 && MaxExperiencePickups > 0 && ExperienceSpawnAmount > 0);

	if(bArtifacts || bAdrenaline || bExperience)
	{
		for(N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint)
		{
			if (PathNode(N) != None && !N.IsA('FlyingPathNode'))
				PathNodes[PathNodes.length] = PathNode(N);
		}
		
		if(PathNodes.Length == 0)
		{
			Warn("No eligible path nodes have been found - artifact / adrenaline spwaning disabled!");
			Destroy();
			return;
		}

		if(bArtifacts)
		{
			for(x = 0; x < AvailableArtifacts.length; x++)
				TotalArtifactChance += AvailableArtifacts[x].Chance;
		}
	}
	else
	{
		Destroy();
	}
}

function Initialize(MutTitanRPG RPGMut)
{
	local int x;

	x = 0;
	while(x < AvailableArtifacts.length)
	{
		if(AvailableArtifacts[x].ArtifactClass == None ||
			!RPGMut.GameSettings.AllowArtifact(AvailableArtifacts[x].ArtifactClass))
		{
			AvailableArtifacts.Remove(x, 1);
		}
		else if(AvailableArtifacts[x].ArtifactClass.default.PickupClass == None)
		{
			Warn(AvailableArtifacts[x].ArtifactClass $ " does not have a pickup class assigned!");
			AvailableArtifacts.Remove(x, 1);
		}
		else
		{
			x++;
		}
	}
}

function MatchStarting()
{
	SetTimer(SpawnDelay, true);
}

// select a random artifact based on the Chance entries in the artifact list and return its index
function int GetRandomArtifactIndex()
{
	local int i;
	local int Chance;

	Chance = Rand(TotalArtifactChance);
	for (i = 0; i < AvailableArtifacts.Length; i++)
	{
		Chance -= AvailableArtifacts[i].Chance;
		if (Chance < 0)
		{
			return i;
		}
	}
}

function Timer()
{
	local int Chance, Count, x;
	local bool bTryAgain;

	//Adrenaline
	if(bAdrenaline)
	{
		for (x = 0; x < CurrentAdrenPickups.length; x++)
		{
			if (CurrentAdrenPickups[x] == None)
			{
				CurrentAdrenPickups.Remove(x, 1);
				x--;
			}
		}
		
		for(x = 0; CurrentAdrenPickups.length < MaxAdrenalinePickups && x < AdreanlineSpawnAmount; x++)
		{
			SpawnAdrenaline();
		}
	}
    
    //Experience
	if(bExperience)
	{
		for (x = 0; x < CurrentExperiencePickups.length; x++)
		{
			if (CurrentExperiencePickups[x] == None)
			{
				CurrentExperiencePickups.Remove(x, 1);
				x--;
			}
		}
		
		for(x = 0; CurrentExperiencePickups.length < MaxExperiencePickups && x < ExperienceSpawnAmount; x++)
		{
			SpawnExperience();
		}
	}

	//Artifacts
	if(bArtifacts)
	{
		for (x = 0; x < CurrentArtifacts.length; x++)
		{
			if (CurrentArtifacts[x] == None)
			{
				CurrentArtifacts.Remove(x, 1);
				x--;
			}
		}

		if(CurrentArtifacts.length >= MaxArtifacts)
			return;

		if(CurrentArtifacts.length >= AvailableArtifacts.length)
		{
			//there's one of everything already
			Chance = GetRandomArtifactIndex();
			SpawnArtifact(Chance);
			return;
		}

		while (Count < 250)
		{
			// FIXME: make this not slow (just advance through list until we find one that isn't in use)
			Chance = GetRandomArtifactIndex();
			for (x = 0; x < CurrentArtifacts.length; x++)
			{
				if (CurrentArtifacts[x].Class == AvailableArtifacts[Chance].ArtifactClass)
				{
					bTryAgain = true;
					x = CurrentArtifacts.length;
				}
			}
				
			if(!bTryAgain)
			{
				SpawnArtifact(Chance);
				return;
			}
			
			bTryAgain = false;
			Count++;
		}
	}
}

function PathNode FindSpawnLocation(class<Actor> ForWhat)
{
	local PathNode PathNode;
	local Pickup Pickup;
	local int i;
	local bool bAlreadyUsed;
	
	for(i = 0; i < 20; i++) //max 20 tries
	{
		PathNode = PathNodes[Rand(PathNodes.Length)];

		//check whether there's already a pickup here
		bAlreadyUsed = false;
		foreach PathNode.VisibleCollidingActors(class'Pickup', Pickup, ForWhat.default.CollisionRadius)
			bAlreadyUsed = true;
			
		if(!bAlreadyUsed)
			return PathNode;
	}
	return None;
}

function SpawnAdrenaline()
{
	local PathNode PathNode;
	local AdrenalinePickup APickup;

	PathNode = FindSpawnLocation(class'XPickups.AdrenalinePickup');
	if(PathNode != None)
	{
		APickup = spawn(class'XPickups.AdrenalinePickup', , , PathNode.Location);
		
		if (APickup == None)
			return;
			
		APickup.RespawnEffect();
		APickup.RespawnTime = 0.0;
		APickup.AddToNavigation();
		CurrentAdrenPickups[CurrentAdrenPickups.length] = APickup;
	}
}

function SpawnExperience()
{
	local PathNode PathNode;
	local ExperiencePickup XPickup;

	PathNode = FindSpawnLocation(class'ExperiencePickup');
	if(PathNode != None)
	{
		XPickup = spawn(class'ExperiencePickup', , , PathNode.Location);
		
		if (XPickup == None)
			return;
			
		XPickup.RespawnEffect();
		XPickup.RespawnTime = 0.0;
		XPickup.AddToNavigation();
		CurrentExperiencePickups[CurrentExperiencePickups.length] = XPickup;
	}
}

function SpawnArtifact(int Index)
{
	local PathNode PathNode;
	local Pickup APickup;
	local Controller C;
	local RPGArtifact Inv;
	local int NumMonsters, PickedMonster, CurrentMonster;

	if (Level.Game.IsA('Invasion'))
	{
		NumMonsters = int(Level.Game.GetPropertyText("NumMonsters"));
		if (NumMonsters <= CurrentArtifacts.length)
		{
			return;
		}
		
		do
		{
			PickedMonster = Rand(NumMonsters);
			for (C = Level.ControllerList; C != None; C = C.NextController)
			{
				if (C.Pawn != None && C.Pawn.IsA('Monster') && !C.IsA('FriendlyMonsterController'))
				{
					if (CurrentMonster >= PickedMonster)
					{
						//Assumes monster doesn't get inventory from anywhere else!
						if (RPGArtifact(C.Pawn.Inventory) == None)
						{
							Inv = spawn(AvailableArtifacts[Index].ArtifactClass);
							Inv.GiveTo(C.Pawn);
							break;
						}
					}
					else
						CurrentMonster++;
				}
			}
		}
		until (Inv != None)

		if(Inv != None)
			CurrentArtifacts[CurrentArtifacts.length] = Inv;
	}
	else
	{
		PathNode = FindSpawnLocation(AvailableArtifacts[Index].ArtifactClass.default.PickupClass);
		if(PathNode != None)
		{
			APickup = spawn(AvailableArtifacts[Index].ArtifactClass.default.PickupClass,,, PathNode.Location);
		
			if (APickup == None)
				return;
				
			APickup.RespawnEffect();
			APickup.RespawnTime = 0.0;
			APickup.AddToNavigation();
			APickup.bDropped = true;
			APickup.Inventory = spawn(AvailableArtifacts[Index].ArtifactClass);
			
			CurrentArtifacts[CurrentArtifacts.length] = RPGArtifact(APickup.Inventory);
		}
	}
}

defaultproperties
{
	SpawnDelay=15
	MaxArtifacts=25
	AdreanlineSpawnAmount=5
	MaxAdrenalinePickups=25
    ExperienceSpawnAmount=1
    MaxExperiencePickups=5
}
