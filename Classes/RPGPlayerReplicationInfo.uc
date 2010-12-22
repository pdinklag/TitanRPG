//If you were looking for RPGStatsInv, this replaces it. ~pd
class RPGPlayerReplicationInfo extends LinkedReplicationInfo
	DependsOn(RPGAbility)
	Config(TitanRPG);

//server
var RPGData DataObject;
var MutTitanRPG RPGMut;

var bool bImposter;

struct OldRPGWeaponInfo
{
	var RPGWeapon Weapon;
	var class<Weapon> ModifiedClass;
};
var array<OldRPGWeaponInfo> OldRPGWeapons;

var RPGAIBuild AIBuild;
var int AIBuildAction;

var bool bPlayerLevelsSent;
var int SendAbilityConfig;

var RPGPlayerLevelInfo PlayerLevel;

//Weapon and Artifact Restoration
var DruidsOldWeaponHolder OldWeaponHolder;
var class<Powerups> LastSelectedPowerupType;

//these are used to track constant suiciding
var float LastSuicideTime;
var int RecentSuicideCount; //amount of recent suicides
var int SuicidePenalty; //some skills will only work limited as long as this is greater than 0
var config float SuicideCountDuration;
var config int SuicidePenaltyTreshold; //if this many recent suicides were detected, increase the penalty
var config int SuicidePenaltyIncrement; //penalty gets increased by this with every violation

//used to grant experience for special accomplishments - TODO: implement
//var int FlakCount, ComboCount, HeadCount, RanoverCount, DaredevilPoints, GoalsScored;

//to detect team changes
var int Team; //info holder for RPGRules, set each spawn
var bool bTeamChanged; //set by RPGRules, reset each spawn

//to detect weapon switches
var Weapon LastPawnWeapon;

//stuff that belongs to me
var array<Vehicle> Turrets;
var array<Monster> Monsters;
var array<Drone> Drones;

//replicated
var int NumMonsters, NumTurrets;

//stats
var int Attack, Defense, AmmoMax, WeaponSpeed;
var int MaxMonsters, MaxDrones, MaxTurrets;

var float HealingExpMultiplier;

//replicated server->client
var Controller Controller;
var PlayerReplicationInfo PRI;

var string RPGName;
var int RPGLevel, PointsAvailable, NeededExp;
var float Experience;
var array<RPGAbility> Abilities;

var bool bGameEnded;

//replicated client->server
struct ArtifactOrderStruct
{
	var class<RPGArtifact> ArtifactClass;
	var string ArtifactID;
	var bool bShowAlways;
};
var array<ArtifactOrderStruct> ArtifactOrder;

//rebuild info
var bool bAllowRebuild;
var int RebuildCost;
var int RebuildMaxLevelLoss;

//client
var bool bClientSetup;

var RPGInteraction Interaction;
var RPGMenu Menu;

var int AbilitiesReceived, AbilitiesTotal;

var array<RPGAbility> AllAbilities;
var array<class<RPGArtifact> > AllArtifacts;

//adrenaline gain modification
var Controller AboutToKill;
var class<DamageType> KillingDamType;
var int AdrenalineBeforeKill;

//Text
var localized string GameRestartingText, ImposterText, LevelUpText, IntroText;
var localized string SuicidePenaltyWarningText, SuicidePenaltyText;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Controller, RPGName,
		bAllowRebuild, RebuildCost, RebuildMaxLevelLoss;
	reliable if(Role == ROLE_Authority && bNetDirty)
		bImposter, RPGLevel, Experience, PointsAvailable, NeededExp,
		bGameEnded,
		NumMonsters, MaxMonsters,
		NumTurrets, MaxTurrets;
	reliable if(Role == ROLE_Authority)
		ClientReInitMenu, ClientEnableRPGMenu,
		ClientModifyVehicleWeaponFireRate,
		ClientNotifyExpGain, ClientShowHint,
		ClientSetName, ClientGameEnded,
		ClientCheckArtifactClass,
		ClientSwitchToWeapon; //moved from TitanPlayerController for better compatibility
	reliable if(Role < ROLE_Authority)
		ServerBuyAbility, ServerNoteActivity,
		ServerSwitchBuild, ServerResetData, ServerRebuildData,
		ServerClearArtifactOrder, ServerAddArtifactOrderEntry, ServerSortArtifacts,
		ServerGetArtifact, ServerActivateArtifact, //moved from TitanPlayerController for better compatibility
		ServerDestroyTurrets, ServerKillMonsters;
}

static function RPGPlayerReplicationInfo CreateFor(Controller C)
{
	local PlayerReplicationInfo PRI;
	local RPGPlayerReplicationInfo RPRI;

	PRI = C.PlayerReplicationInfo;
	
	if(PRI == None)
		return None;
	
	RPRI = GetForPRI(PRI);
	if(RPRI != None)
	{
		Warn(C.GetHumanReadableName() @ "already has an RPRI!");
		return None;
	}

	Log("Creating an RPRI for " @ C @ "(" $ C.GetHumanReadableName() $ ")");
	RPRI = C.Spawn(class'RPGPlayerReplicationInfo', C);
	RPRI.NextReplicationInfo = PRI.CustomReplicationInfo;
	PRI.CustomReplicationInfo = RPRI;

	return RPRI;
}

static function RPGPlayerReplicationInfo GetForPRI(PlayerReplicationInfo PRI)
{
	local LinkedReplicationInfo LRI;
	
	if(PRI != None)
	{
		for(LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo)
		{
			if(RPGPlayerReplicationInfo(LRI) != None)
				return RPGPlayerReplicationInfo(LRI);
		}
	}
	return None;
}

static function RPGPlayerReplicationInfo GetFor(Controller C)
{
	if(C == None)
		return None;
	
	return GetForPRI(C.PlayerReplicationInfo);
}

//for clients
static function RPGPlayerReplicationInfo GetLocalRPRI(LevelInfo Level)
{
	return GetFor(Level.GetLocalPlayerController());
}

function ModifyStats()
{
	local int x;
	
	MaxMonsters = RPGMut.MaxMonsters;
	MaxDrones = RPGMut.MaxDrones;
	MaxTurrets = RPGMut.MaxTurrets;
	
	AmmoMax = default.AmmoMax;
	Attack = default.Attack;
	Defense = default.Defense;
	WeaponSpeed = default.WeaponSpeed;
	HealingExpMultiplier = class'RPGGameStats'.default.EXP_Healing;
	
	for(x = 0; x < Abilities.Length; x++)
	{
		if(Abilities[x].bAllowed)
			Abilities[x].ModifyRPRI();
	}
}

simulated event BeginPlay()
{
	local int i;
	local string PlayerName;
	local RPGData data;

	Super.BeginPlay();
	
	if(Role == ROLE_Authority)
	{
		Controller = Controller(Owner);
		PRI = Controller.PlayerReplicationInfo;
		
		Log("RPRI.BeginPlay for" @ PRI.PlayerName, 'TitanRPG');

		RPGMut = class'MutTitanRPG'.static.Instance(Level);
		if(RPGMut == None)
		{
			Warn("TitanRPG mutator no longer available - cancelling!");
			Destroy();
			return;
		}

		//copy rebuild info for replication
		bAllowRebuild = RPGMut.bAllowRebuild;
		RebuildCost = RPGMut.RebuildCost;
		RebuildMaxLevelLoss = RPGMut.RebuildMaxLevelLoss;

		bGameEnded = false;
		bImposter = false;
		while(true)
		{
			PlayerName = RPGMut.ProcessPlayerName(Self);

			data = RPGData(FindObject("Package." $ PlayerName, class'RPGData'));
			if (data == None)
				data = new(None, PlayerName) class'RPGData';

			if(data.LV == 0) //new player
			{
				data.LV = RPGMut.StartingLevel;
				data.PA = RPGMut.StartingStatPoints + RPGMut.PointsPerLevel * (data.LV - 1);
				
				if(RPGMut.Levels.Length > data.LV)
					data.XN = RPGMut.Levels[data.LV];
				else
					data.XN = RPGMut.Levels[RPGMut.Levels.Length - 1];
					
				if (PlayerController(Controller) != None)
					data.ID = PlayerController(Controller).GetPlayerIDHash();
				else
					data.ID = "Bot";
					
				break;
			}
			else //returning player
			{
				if((PlayerController(Controller) != None && !(PlayerController(Controller).GetPlayerIDHash() ~= data.ID)) ||
					(AIController(Controller) != None && data.ID != "Bot"))
				{
					//imposter using somebody else's name
					bImposter = true;
					
					if(PlayerController(Controller) != None)
						PlayerController(Controller).ClientOpenMenu(
							"<? echo($packageName); ?>.RPGImposterMessageWindow");
						
					//Level.Game.ChangeName(Controller, string(Rand(65535)), true); //That's gotta suck, having a number for a name
					Level.Game.ChangeName(Controller, Controller.GetHumanReadableName() $ "_Imposter", true);
				}
				else
					break;
			}
		}
		
		//Instantiate abilities
		for(i = 0; i < RPGMut.Abilities.Length; i++)
		{
			AllAbilities[i] = Spawn(RPGMut.Abilities[i], Controller);
			AllAbilities[i].RPRI = Self;
			AllAbilities[i].Index = i;
			AllAbilities[i].bIsStat = (class'Util'.static.InArray(RPGMut.Abilities[i], RPGMut.Stats) >= 0);
		}

		LoadData(data);
		
		if(AIBuild != None)
		{
			if(Controller.IsA('Bot'))
				AIBuild.InitBot(Bot(Controller));
		
			AIBuild.Build(Self);
		}

		//Inform others
		PlayerLevel = Spawn(class'RPGPlayerLevelInfo');
		PlayerLevel.PRI = PRI;
		PlayerLevel.RPGLevel = RPGLevel;
		PlayerLevel.Experience = Experience;
		PlayerLevel.ExpNeeded = NeededExp;
	}
	
	Log("RPGPlayerReplicationInfo for" @ RPGName);
}

simulated event Destroyed()
{
	local LinkedReplicationInfo LRI;
	local int i;
	
	if(PRI != None)
	{
		if(PRI.CustomReplicationInfo == Self)
		{
			PRI.CustomReplicationInfo = NextReplicationInfo;
		}
		else
		{
			for(LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo)
			{
				if(LRI.NextReplicationInfo == Self)
				{
					LRI.NextReplicationInfo = NextReplicationInfo;
					break;
				}
			}
		}
	}
	
	if(Role == ROLE_Authority)
	{
		for(i = 0; i < AllAbilities.Length; i++)
			AllAbilities[i].Destroy();
	
		PlayerLevel.Destroy();
	}
	
	if(Interaction != None)
		Interaction.Remove();
	
	Interaction = None;
	RPGMut = None;
}

//clients only
simulated function class<RPGArtifact> GetArtifactClass(string ID)
{
	local int i;
	
	for(i = 0; i < AllArtifacts.Length; i++)
	{
		if(AllArtifacts[i].default.ArtifactID ~= ID)
			return AllArtifacts[i];
	}
	return None;
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	
	if(Controller != None && Role == ROLE_Authority)
		Controller.AdrenalineMax = Controller.default.AdrenalineMax; //fix the build switching exploit
	
	if(Level.NetMode != NM_DedicatedServer)
		ClientSetup(); //try setup. if it fails, it's tried again every tick
}

simulated function ClientSetup()
{
	local int x, i;
	local RPGReplicationInfo RRI;
	local class<RPGArtifact> AClass;
	local ArtifactOrderStruct OrderEntry;

	if(Controller == None || Controller.PlayerReplicationInfo == None)
		return; //wait

	RRI = class'RPGReplicationInfo'.static.Get(Level);
	if(Level.NetMode != NM_Standalone && RRI == None)
		return; //wait
	
	PRI = Controller.PlayerReplicationInfo;
	
	NextReplicationInfo = PRI.CustomReplicationInfo;
	PRI.CustomReplicationInfo = Self;
	
	xPlayer(Controller).ComboList[0] = class'RPGComboSpeed';
	
	if(Role < ROLE_Authority) //not offline
	{
		AbilitiesTotal = RRI.NumAbilities;
	
		for(x = 0; x < RRI.MAX_Artifacts && RRI.Artifacts[x] != None; x++)
			AllArtifacts[x] = RRI.Artifacts[x];
	}
	else if(Level.NetMode == NM_Standalone) //offline
	{
		AbilitiesTotal = RPGMut.Abilities.Length;
		AllArtifacts = RPGMut.Artifacts;
	}
	
	if(PlayerController(Controller) != None)
	{
		Interaction = RPGInteraction(
			PlayerController(Controller).Player.InteractionMaster.AddInteraction(
				"<? echo($packageName); ?>.RPGInteraction", PlayerController(Controller).Player));
	}
	
	if(Interaction != None)
		Interaction.RPRI = Self;
	else
		Warn("Could not create RPGInteraction!");
	
	//build artifact order
	ArtifactOrder.Remove(0, ArtifactOrder.Length);
	ServerClearArtifactOrder();
	
	if(Interaction.CharSettings != None)
	{
		//load order from settings
		for(x = 0; x < Interaction.CharSettings.ArtifactOrderConfig.Length; x++)
		{
			AClass = GetArtifactClass(Interaction.CharSettings.ArtifactOrderConfig[x].ArtifactID);

			OrderEntry.ArtifactClass = AClass;
			OrderEntry.ArtifactID = Interaction.CharSettings.ArtifactOrderConfig[x].ArtifactID;
			OrderEntry.bShowAlways = Interaction.CharSettings.ArtifactOrderConfig[x].bShowAlways;
			
			ArtifactOrder[ArtifactOrder.Length] = OrderEntry;
			ServerAddArtifactOrderEntry(OrderEntry);
		}
		ServerSortArtifacts();
	}

	//add all artifacts that were not in the settings to the end
	for(x = 0; x < AllArtifacts.Length; x++)
	{
		i = FindOrderEntry(AllArtifacts[x]);
		if(i == -1)
		{
			OrderEntry.ArtifactClass = AllArtifacts[x];
			OrderEntry.ArtifactID = AllArtifacts[x].default.ArtifactID;
			OrderEntry.bShowAlways = false;
			
			ArtifactOrder[ArtifactOrder.Length] = OrderEntry;
			ServerAddArtifactOrderEntry(OrderEntry);
		}
	}
	
	if(AbilitiesReceived >= AbilitiesTotal || Role == ROLE_Authority)
		ClientEnableRPGMenu();
	
	bClientSetup = true;
}

simulated function int FindOrderEntry(class<RPGArtifact> AClass)
{
	local int i;
	
	for(i = 0; i < ArtifactOrder.Length; i++)
	{
		if(ArtifactOrder[i].ArtifactClass == AClass)
			return i;
	}
	return -1;
}

function ServerSortArtifacts()
{
	local Inventory Inv;
	local RPGArtifact A;
	local array<RPGArtifact> CurrentArtifacts;
	local int i;

	if(Controller.Pawn != None)
	{
		//strip out all artifacts
		Inv = Controller.Pawn.Inventory;
		while(Inv != None)
		{
			if(Inv.IsA('RPGArtifact'))
			{
				A = RPGArtifact(Inv);
				CurrentArtifacts[CurrentArtifacts.Length] = A;
				
				Inv = A.Inventory;
				
				A.StripOut();
			}
			else
			{
				Inv = Inv.Inventory;
			}
		}
		
		//sort them back in
		for(i = 0; i < CurrentArtifacts.Length; i++)
			CurrentArtifacts[i].SortIn();
	}
}

function ServerClearArtifactOrder()
{
	ArtifactOrder.Length = 0;
}

function ServerAddArtifactOrderEntry(ArtifactOrderStruct OrderEntry)
{
	if(FindOrderEntry(OrderEntry.ArtifactClass) == -1)
		ArtifactOrder[ArtifactOrder.Length] = OrderEntry;
}

simulated function ResendArtifactOrder()
{
	local int i;

	ServerClearArtifactOrder();
	for(i = 0; i < ArtifactOrder.Length; i++)
		ServerAddArtifactOrderEntry(ArtifactOrder[i]);
	
	ServerSortArtifacts();
}

function CheckArtifactClass(class<RPGArtifact> AClass)
{
	ClientCheckArtifactClass(AClass);
}

simulated function ClientCheckArtifactClass(class<RPGArtifact> AClass)
{
	local ArtifactOrderStruct OrderEntry;

	//make sure that this artifact class gets listed in the order so the interaction shows it
	if(FindOrderEntry(AClass) == -1)
	{
		OrderEntry.ArtifactClass = AClass;
		OrderEntry.ArtifactID = AClass.default.ArtifactID;
		OrderEntry.bShowAlways = false;
		
		ArtifactOrder[ArtifactOrder.Length] = OrderEntry;
		ServerAddArtifactOrderEntry(OrderEntry);
		ServerSortArtifacts();
	}
}

simulated function ReceiveAbility(RPGAbility Ability)
{
	local int i;

	Ability.SetOwner(Controller);

	if(class'Util'.static.InArray(Ability, AllAbilities) == -1)
	{
		AbilitiesReceived++;
		AllAbilities[Ability.Index] = Ability;

		if(Ability.AbilityLevel > 0)
		{
			for(i = 0; i < Abilities.Length; i++)
			{
				if(Abilities[i].BuyOrderIndex > Ability.BuyOrderIndex)
					break;
			}
			Abilities.Insert(i, 1);
			Abilities[i] = Ability;
		}
	}
	else
	{
		Warn("Received ability" @ Ability @ "twice!");
	}
	
	if(AbilitiesReceived == AbilitiesTotal)
		ClientEnableRPGMenu();
}

simulated function CheckPlayerViewShake()
{
	local float ShakeScaling;

	if(Controller.IsA('PlayerController'))
	{
		ShakeScaling = VSize(PlayerController(Controller).ShakeRotMax) / 7500.0f;
		if(ShakeScaling > 1.0f)
		{
			PlayerController(Controller).ShakeRotMax /= ShakeScaling;
			PlayerController(Controller).ShakeRotTime /= ShakeScaling;
			PlayerController(Controller).ShakeOffsetMax /= ShakeScaling;
		}
	}
}

simulated event Tick(float dt)
{
	local int x;

	if(Level.NetMode != NM_DedicatedServer)
	{
		if(!bClientSetup)
			ClientSetup();
	}
	
	if(Controller == None)
	{
		Log("Destroyed RPRI for" @ RPGName, 'TitanRPG');
		Destroy();
		return;
	}
	
	CheckPlayerViewShake();
	
	if(Role == ROLE_Authority)
	{
		if(RecentSuicideCount > 0 && (Level.TimeSeconds - LastSuicideTime) > SuicideCountDuration)
			RecentSuicideCount = 0;
		
		//Check weapon
		if(Controller.Pawn != None && !Controller.Pawn.IsA('Vehicle'))
		{
			if(Controller.Pawn.Weapon != LastPawnWeapon)
			{
				if(Controller.Pawn.Weapon != None)
				{
					for(x = 0; x < Abilities.Length; x++)
					{
						if(Abilities[x].bAllowed)
							Abilities[x].ModifyWeapon(Controller.Pawn.Weapon);
					}
				}
				LastPawnWeapon = Controller.Pawn.Weapon;
			}
		}
		else if(Controller.Pawn == None)
		{
			LastPawnWeapon = None;
		}
		
		//Clean monsters
		x = 0;
		while(x < Monsters.Length)
		{
			if(Monsters[x] == None)
			{
				NumMonsters--;
				Monsters.Remove(x, 1);
			}
			else
				x++;
		}
		
		//Clean turrets
		x = 0;
		while(x < Turrets.Length)
		{
			if(Turrets[x] == None)
			{
				NumTurrets--;
				Turrets.Remove(x, 1);
			}
			else
				x++;
		}
		
		//Clean drones
		x = 0;
		while(x < Drones.Length)
		{
			if(Drones[x] == None)
				Drones.Remove(x, 1);
			else
				x++;
		}
	}
}

function ServerNoteActivity()
{
	if(PlayerController(Controller) != None)
		PlayerController(Controller).LastActiveTime = Level.TimeSeconds;
}

simulated function ClientReInitMenu()
{
	if(Menu != None)
		Menu.InitFor(Self);
}

function AwardExperience(float exp)
{
	local LevelUpEffect Effect;
	local int Count;
	
	if(bGameEnded)
		return;
	
	if(PlayerController(Controller) != None && Level.Game.NumPlayers < class'MutTitanRPG'.default.MinHumanPlayersForExp)
		return;
	
	if(RPGMut.GameSettings.ExpScale > 0.0)
		exp *= RPGMut.GameSettings.ExpScale; //scale xp gain
	
	Experience = FMax(0.0, Experience + exp);
	ClientNotifyExpGain(exp);
	
	while(Experience >= NeededExp && Count < 10000)
	{
		Count++;
		
		RPGLevel++;
		PointsAvailable += RPGMut.PointsPerLevel;
		Experience -= float(NeededExp);
		
		if(RPGLevel < RPGMut.Levels.Length)
			NeededExp = RPGMut.Levels[RPGLevel];
		
		if(Count <= RPGMut.MaxLevelupEffectStacking && Controller != None && Controller.Pawn != None)
		{
			Effect = Controller.Pawn.spawn(class'LevelUpEffect', Controller.Pawn);
			Effect.SetDrawScale(Controller.Pawn.CollisionRadius / Effect.CollisionRadius);
			Effect.Initialize();
		}
	}
	
	if(Count > 0)
	{
		Level.Game.BroadCastLocalized(Self, class'GainLevelMessage', RPGLevel, PRI);
		ClientShowHint(LevelUpText);
		
		if(AIBuild != None)
			AIBuild.Build(Self);
		
		PlayerLevel.RPGLevel = RPGLevel;
		PlayerLevel.ExpNeeded = NeededExp;
	}
	
	PlayerLevel.Experience = Experience;
}

simulated function ClientNotifyExpGain(float Amount)
{
	if(Interaction != None)
		Interaction.NotifyExpGain(Amount);
}

simulated function ClientShowHint(string Hint)
{
	if(Interaction != None)
		Interaction.ShowHint(Hint);
}

simulated function ClientEnableRPGMenu()
{
	if(Interaction != None)
	{
		Interaction.bMenuEnabled = true;
		Interaction.ShowHint(IntroText);
	}
}

simulated function int HasAbility(class<RPGAbility> AbilityClass)
{
	local int x;
	
	for(x = 0; x < Abilities.Length; x++)
	{
		if(Abilities[x].class == AbilityClass)
			return Abilities[x].AbilityLevel;
	}
	return 0;
}

simulated function RPGAbility GetOwnedAbility(class<RPGAbility> AbilityClass)
{
	local int x;
	
	for(x = 0; x < Abilities.Length; x++)
	{
		if(Abilities[x].class == AbilityClass)
			return Abilities[x];
	}
	return None;
}

simulated function RPGAbility GetAbility(class<RPGAbility> AbilityClass)
{
	local int x;
	
	for(x = 0; x < AllAbilities.Length; x++)
	{
		if(AllAbilities[x].class == AbilityClass)
			return AllAbilities[x];
	}
	return None;
}

function bool ServerBuyAbility(RPGAbility Ability, optional int Amount)
{
	if(Ability.Buy(Amount))
	{
		ModifyStats();
		return true;
	}
	else
	{
		return false;
	}
}

function ModifyPlayer(Pawn Other)
{
	local Inventory Inv;
	local int i;
	
	if(Level.Game.bTeamGame)
		Team = PRI.Team.TeamIndex;

	//must be emptied to avoid lifetime PDP "protection"...
	OldRPGWeapons.Remove(0, OldRPGWeapons.Length);
	
	if(Other != Controller.Pawn)
	{
		Log("RPGReplicationInfo was told to modify a Pawn that doesn't belong to this RPRI's Controller! Pawn is " $ 
			Other.GetHumanReadableName() $ ", RPRI belongs to " $ PRI.PlayerName, 'TitanRPG');
			
		return;
	}

	//Call abilities
	for(i = 0; i < Abilities.Length; i++)
	{
		if(Abilities[i].bAllowed)
			Abilities[i].ModifyPawn(Other);
	}
	
	//Upon a team change, simulate Denial 4 if not present
	if(bTeamChanged &&
		OldWeaponHolder != None &&
		HasAbility(class'AbilityDenial') < class'AbilityDenial'.default.MaxLevel &&
		HasAbility(class'AbilityDenial_TC0X') < class'AbilityDenial_TC0X'.default.MaxLevel)
	{
		class'AbilityDenial'.static.RestoreOldWeapons(Other, Self);
	}
	
	bTeamChanged = false;
	
	//Restore last selected artifact
	if(LastSelectedPowerupType != None)
	{
		Inv = Other.FindInventoryType(LastSelectedPowerupType);
		if(Inv != None)
			Other.SelectedItem = Powerups(Inv);
	}
	
	if(Other.SelectedItem == None) //if not possible, do this
		Other.NextItem();
	
	//Reduce penalty
	if(SuicidePenalty > 0)
		SuicidePenalty--;
}

function AddDrone(Drone D)
{
	Drones[Drones.Length] = D;
}

function AddMonster(Monster M)
{
	local int i;
	
	Monsters[Monsters.Length] = M;
	NumMonsters++;
	
	for(i = 0; i < Abilities.Length; i++)
	{
		if(Abilities[i].bAllowed)
			Abilities[i].ModifyMonster(M, Controller.Pawn);
	}
}

function ServerKillMonsters()
{
	while(Monsters.Length > 0)
	{
		if(Monsters[0] != None)
			Monsters[0].Suicide();
		
		Monsters.Remove(0, 1);
	}
	NumMonsters = 0;
}

function AddTurret(Vehicle T)
{
	local int i;
	
	Turrets[Turrets.Length] = T;
	NumTurrets++;
	
	for(i = 0; i < Abilities.Length; i++)
	{
		if(Abilities[i].bAllowed)
			Abilities[i].ModifyTurret(T, Controller.Pawn);
	}
}

function ServerDestroyTurrets()
{
	while(Turrets.Length > 0)
	{
		if(Turrets[0] != None)
		{
			if(Turrets[0].Driver != None)
				Turrets[0].KDriverLeave(true);
			
			if(Turrets[0].Controller != None && !Turrets[0].Controller.IsA('PlayerController'))
				Turrets[0].Controller.Destroy();
			
			Turrets[0].Destroy();
		}
		
		Turrets.Remove(0, 1);
	}
	NumTurrets = 0;
}

function ModifyVehicleFireRate(Vehicle V, float Modifier)
{
	local int i;
	local ONSVehicle OV;
	local ONSWeaponPawn WP;
	local Inventory Inv;

	OV = ONSVehicle(V);
	if (OV != None)
	{
		for(i = 0; i < OV.Weapons.length; i++)
		{
			ModifyVehicleWeaponFireRate(OV.Weapons[i], Modifier);
			ClientModifyVehicleWeaponFireRate(OV.Weapons[i], Modifier);
		}
	}
	else
	{
		WP = ONSWeaponPawn(V);
		if (WP != None)
		{
			ModifyVehicleWeaponFireRate(WP.Gun, Modifier);
			ClientModifyVehicleWeaponFireRate(WP.Gun, Modifier);
		}
		else //some other type of vehicle (usually ASVehicle) using standard weapon system
		{
			//at this point, the vehicle's Weapon is not yet set, but it should be its only inventory
			for(Inv = V.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				if(Inv.IsA('Weapon'))
				{
					ModifyVehicleWeaponFireRate(Weapon(Inv), Modifier);
					ClientModifyVehicleWeaponFireRate(Weapon(Inv), Modifier);
				}
			}
		}
	}
}

function NotifySuicide()
{
	if(Level.TimeSeconds - LastSuicideTime < SuicideCountDuration)
	{
		RecentSuicideCount++;
		
		if(SuicidePenalty > 0 || RecentSuicideCount >= SuicidePenaltyTreshold)
		{
			SuicidePenalty += SuicidePenaltyIncrement;
			Log(RPGName $ " received a penalty for repeatedly suiciding (" $ SuicidePenalty $ ").", 'TitanRPG');
			
			ClientShowHint(Repl(SuicidePenaltyText, "$1", SuicidePenalty));
		}
		else if(RecentSuicideCount + 1 >= SuicidePenaltyTreshold)
		{
			ClientShowHint(SuicidePenaltyWarningText);
		}
	}
	
	LastSuicideTime = Level.TimeSeconds;
}

simulated function ModifyVehicleWeaponFireRate(Actor W, float Modifier)
{
	if(W != None)
	{
		if(W.IsA('ONSWeapon'))
		{
			ONSWeapon(W).SetFireRateModifier(Modifier);
			return;
		}
		else if(W.IsA('Weapon'))
		{
			class'Util'.static.SetWeaponFireRate(Weapon(W), Modifier);
			return;
		}
		else
		{
			Warn("Could not set fire rate for " $ W $ "!");
		}
	}
}

simulated function ClientModifyVehicleWeaponFireRate(Actor W, float Modifier)
{
	if(Level.NetMode != NM_DedicatedServer)
		ModifyVehicleWeaponFireRate(W, Modifier);
}

simulated function ClientSetName(string NewName)
{
	if(PlayerController(Controller) != None)
		PlayerController(Controller).SetName(NewName);
}

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	local int i;
	local float Modifier;
	
	Modifier = 1.0f + 0.01f * float(WeaponSpeed);
	ModifyVehicleFireRate(V, Modifier);

	for(i = 0; i < Abilities.length; i++)
	{
		if(Abilities[i].bAllowed)
			Abilities[i].ModifyVehicle(V);
	}
}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
	local int i;
	
	for(i = 0; i < Abilities.Length; i++)
	{
		if(Abilities[i].bAllowed)
			Abilities[i].UnModifyVehicle(V);
	}
}

function ServerSwitchBuild(string NewBuild)
{
	Log(RPGName $ " switches build to " $ NewBuild, 'TitanRPG');
	RPGMut.SwitchBuild(Self, NewBuild);
}

function GameEnded()
{
	bGameEnded = true;
	ClientGameEnded();
}

simulated function ClientGameEnded()
{
	//anything to do?
}

function ServerResetData()
{
	local string OwnerID;

	Log(PRI.PlayerName $ " - RESET!", 'TitanRPG');

	OwnerID = DataObject.ID;

	DataObject.ClearConfig();
	DataObject = new(None, string(DataObject.Name)) class'RPGData';

	DataObject.ID = OwnerID;
	DataObject.LV = RPGMut.StartingLevel;
	DataObject.PA = RPGMut.StartingStatPoints + RPGMut.PointsPerLevel * (DataObject.LV - 1);
	DataObject.XN = RPGMut.Levels[DataObject.LV];
	
	DataObject.AA = 0;
	DataObject.AI = "";
	
	DataObject.SaveConfig();

	Level.Game.BroadCastLocalized(Self, class'GainLevelMessage', RPGMut.StartingLevel, PRI);

	Controller.Adrenaline = 0;
	if(Controller.Pawn != None)
		Controller.Pawn.Suicide();
	
	Destroy();
}

function ServerRebuildData()
{
	local float CostLeft;
	local int LevelLoss;

	if(bAllowRebuild)
	{
		Log(PRI.PlayerName $ " - REBUILD!", 'TitanRPG');
		
		DataObject.AB.Length = 0;
		DataObject.AL.Length = 0;
		
		CostLeft = float(RPGMut.RebuildCost);
		while(DataObject.XP < CostLeft && DataObject.LV > RPGMut.StartingLevel && LevelLoss < RPGMut.RebuildMaxLevelLoss)
		{
			CostLeft -= DataObject.XP;
			
			DataObject.LV--;
			DataObject.XP = RPGMut.Levels[DataObject.LV];
			
			LevelLoss++;
		}
		DataObject.XP = FMax(0.0f, DataObject.XP - CostLeft);
		
		DataObject.PA = RPGMut.StartingStatPoints + RPGMut.PointsPerLevel * (DataObject.LV - 1);
		DataObject.XN = RPGMut.Levels[DataObject.LV];
		
		DataObject.SaveConfig();
		
		Level.Game.BroadCastLocalized(Self, class'RebuildMessage', 0, PRI);
		if(LevelLoss > 0)
			Level.Game.BroadCastLocalized(Self, class'GainLevelMessage', DataObject.LV, PRI);
		
		Controller.Adrenaline = 0;
		if(Controller.Pawn != None)
			Controller.Pawn.Suicide();
		
		Destroy();
	}
}

function ServerActivateArtifact(string ArtifactID)
{
	local Inventory Inv;

	if(Controller.Pawn != None)
	{
		for(Inv = Controller.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(RPGArtifact(Inv) != None &&
				RPGArtifact(Inv).ArtifactID ~= ArtifactID)
			{
				RPGArtifact(Inv).Activate();
				break;
			}
		}
	}
}

function ServerGetArtifact(string ArtifactID)
{
	local Inventory Inv;
	
	if(Controller.Pawn != None)
	{
		if(
			RPGArtifact(Controller.Pawn.SelectedItem) != None &&
			RPGArtifact(Controller.Pawn.SelectedItem).ArtifactID ~= ArtifactID)
		{
			return;
		}
		
		for(Inv = Controller.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(RPGArtifact(Inv) != None &&
				RPGArtifact(Inv).ArtifactID ~= ArtifactID)
			{
				Controller.Pawn.SelectedItem = Powerups(Inv);
				break;
			}
		}
	}
}

simulated function ClientSwitchToWeapon(Weapon W)
{
	local Pawn Pawn;
	
	Pawn = Controller.Pawn;
	if(Pawn != None && !Pawn.IsA('Vehicle'))
	{
		if(W == None)
			return;
			
		if(RPGWeapon(W) != None && RPGWeapon(W).ModifiedWeapon == None)
			return;
			
		if(Pawn.PendingWeapon != None && Pawn.PendingWeapon.bForceSwitch)
			return;

		if(Pawn.Weapon == None)
		{
			Pawn.PendingWeapon = W;
			Pawn.ChangedWeapon();
		}
		else if(Pawn.Weapon != W || Pawn.PendingWeapon != None)
		{
			Pawn.PendingWeapon = W;
			Pawn.Weapon.PutDown();
		}
		else if(Pawn.Weapon == W)
		{
			Pawn.Weapon.Reselect();
		}
	}
}

function PickAIBuild()
{
	local array<string> List;

	if(AIBuild != None || AIController(Controller) == None)
		return;
	
	if(DataObject.AI == "")
	{
		List = class'RPGData'.static.GetPerObjectNames("TitanRPGAI", string(class'RPGAIBuild'.name));
		if(List.Length > 0)
		{
			DataObject.AI = List[Rand(List.Length)];
			DataObject.AA = 0;
			
			Log(PRI.PlayerName @ "has picked the AIBuild \"" $ DataObject.AI $ "\".", 'TitanRPG');
		}
		else
		{
			Warn("There are no AIBuilds defined!");
			return;
		}
	}
	
	if(DataObject.AI != "")
	{
		AIBuild = new(None, DataObject.AI) class'RPGAIBuild';
		AIBuildAction = DataObject.AA;
	}
}

function LoadData(RPGData Data)
{
	local RPGAbility Ability;
	local int x, BuyOrderIndex;

	DataObject = Data;
	RPGName = string(Data.Name);

	RPGLevel = DataObject.LV;
	PointsAvailable = DataObject.PA;
	Experience = DataObject.XP;
	NeededExp = DataObject.XN;
	
	Abilities.Remove(0, Abilities.Length);
	
	for(x = 0; x < DataObject.AB.Length; x++)
	{
		Ability = GetAbility(RPGMut.ResolveAbility(DataObject.AB[x]));
		if(Ability != None)
		{
			Ability.AbilityLevel = DataObject.AL[x];
			Ability.BuyOrderIndex = BuyOrderIndex++;
			Abilities[Abilities.Length] = Ability;
		}
		else
		{
			Warn("Could not find ability \"" $ DataObject.AB[x] $ "\"");
		}
	}
	
	ModifyStats();
	PickAIBuild();
}

function SaveData()
{
	local int x;

	if(bImposter)
		return;

	DataObject.LV = RPGLevel;
	DataObject.PA = PointsAvailable;
	DataObject.XP = Experience;
	DataObject.XN = NeededExp;

	DataObject.AB.Remove(0, DataObject.AB.Length);
	DataObject.AL.Remove(0, DataObject.AL.Length);
	
	for(x = 0; x < Abilities.Length; x++)
	{
		DataObject.AB[x] = RPGMut.GetAbilityAlias(Abilities[x].class);
		DataObject.AL[x] = Abilities[x].AbilityLevel;
	}

	DataObject.AA = AIBuildAction;
	DataObject.SaveConfig();
	
	Log("Saved" @ RPGName, 'TitanRPG');
}

defaultproperties
{
	AmmoMax=0
	Attack=0
	Defense=0
	WeaponSpeed=0
	HealingExpMultiplier=0 //gotten from RPGGameStats

	SuicideCountDuration=0
	SuicidePenaltyTreshold=3
	SuicidePenaltyIncrement=3
	SuicidePenaltyWarningText="You are about to receive a penalty|for repeatedly suiciding!"
	SuicidePenaltyText="You have received a suicide penalty for $1 respawns!"

	bNetNotify=True
	bAlwaysRelevant=False
	bOnlyRelevantToOwner=True
	NetUpdateFrequency=4.000000
	RemoteRole=ROLE_SimulatedProxy
	GameRestartingText="Sorry, you cannot perform the desired action once the endgame voting has begun."
	ImposterText="Sorry, your name is already used on this server.|This is a roleplaying game server and every character has a unique name.||Please choose a different name and come back."
	LevelUpText="You have leveled up!|Head to the TitanRPG menu (press L) to buy new abilities."
	IntroText="Press L to open the TitanRPG menu."
}
