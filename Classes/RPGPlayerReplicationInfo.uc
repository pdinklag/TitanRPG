//If you were looking for RPGStatsInv, this replaces it. ~pd
class RPGPlayerReplicationInfo extends LinkedReplicationInfo
	DependsOn(RPGAbility)
	Config(TitanRPG);

const MAX_STATUS = 8;

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

var RPGPlayerLevelInfo PlayerLevel;

//Status icons
var array<RPGStatusIcon> Status;

struct ArtifactCooldown
{
	var class<RPGArtifact> AClass;
	var float TimeLeft;
};
var array<ArtifactCooldown> SavedCooldown;

//Favorite Weapons
struct FavoriteWeapon
{
	var class<Weapon> WeaponClass;
	var class<RPGWeapon> ModifierClass;
};
var array<FavoriteWeapon> FavoriteWeapons;

//Weapon and Artifact Restoration
var class<Powerups> LastSelectedPowerupType;
var FavoriteWeapon LastSelectedWeapon;

var Weapon SwitchToWeapon; //client

/*
	Weapon granting queue
	
	Abilities should no longer directly give weapons to the player, but queue them up
	using QueueWeapon. This allows for central handling of managing granted weapons, e.g.
	by the Favorite Weapon feature
*/
struct GrantWeapon
{
	var class<Weapon> WeaponClass;
	var class<RPGWeapon> ModifierClass;
	var int Modifier;
	var int Ammo[2]; //extra ammo per fire mode. 0 = none, -1 = full
};
var array<GrantWeapon> GrantQueue, GrantFavQueue;

//used to grant experience for special accomplishments - TODO: implement
//var int FlakCount, ComboCount, HeadCount, RanoverCount, DaredevilPoints;

//to detect team changes
var int Team; //info holder for RPGRules, set each spawn
var bool bTeamChanged; //set by RPGRules, reset each spawn

//to detect weapon switches
var Weapon LastPawnWeapon;

//stuff that belongs to me
var array<Vehicle> Turrets;
var array<Monster> Monsters;
var array<ONSMineProjectile> Mines;

//replicated
var int NumMonsters, NumTurrets, NumMines;

//stats
var int AmmoMax, WeaponSpeed;
var int MaxMines, MaxMonsters, MaxTurrets;

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
	var bool bNeverShow;
};
var array<ArtifactOrderStruct> ArtifactOrder;

//rebuild info
var bool bAllowRebuild;
var int RebuildCost;
var int RebuildMaxLevelLoss;

//client
var bool bClientSetup;
var bool bClientSyncDone;

var RPGInteraction Interaction;
var RPGMenu Menu;

var int AbilitiesReceived, AbilitiesTotal;

var array<RPGAbility> AllAbilities;
var array<class<RPGArtifact> > AllArtifacts;

//adrenaline gain modification
var int AdrenalineBeforeKill;

//Sound
var Sound LevelUpSound;

//Text
var localized string GameRestartingText, ImposterText, LevelUpText, IntroText;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Controller, RPGName,
		bAllowRebuild, RebuildCost, RebuildMaxLevelLoss;
	reliable if(Role == ROLE_Authority && bNetDirty)
		bImposter, RPGLevel, Experience, PointsAvailable, NeededExp,
		bGameEnded,
		NumMines, NumMonsters, NumTurrets,
		MaxMines, MaxTurrets, MaxMonsters;
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
		ServerDestroyTurrets, ServerKillMonsters,
		ServerFavoriteWeapon;
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
	
	MaxMines = RPGMut.MaxMines;
	MaxMonsters = RPGMut.MaxMonsters;
	MaxTurrets = RPGMut.MaxTurrets;
	
	AmmoMax = default.AmmoMax;
	WeaponSpeed = default.WeaponSpeed;
	HealingExpMultiplier = class'RPGRules'.default.EXP_Healing;
	
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
					data.XN = RPGMut.Levels[RPGMut.Levels.Length - 1]; //TODO: what to do?
					
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
		
		//Instantiate status icons
		for(i = 0; i < RPGMut.StatusIcons.Length; i++)
		{
			Status[i] = Spawn(RPGMut.StatusIcons[i], Controller);
			Status[i].RPRI = Self;
			Status[i].Index = i;
		}

		//Inform others
		PlayerLevel = Spawn(class'RPGPlayerLevelInfo');
		PlayerLevel.PRI = PRI;
		PlayerLevel.RPGLevel = RPGLevel;
		PlayerLevel.Experience = Experience;
		PlayerLevel.ExpNeeded = NeededExp;
	}
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
				string(class'RPGInteraction'), PlayerController(Controller).Player));
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
			OrderEntry.bNeverShow = Interaction.CharSettings.ArtifactOrderConfig[x].bNeverShow;
			
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
	local Inventory Inv;

	if(Controller.Pawn != None)
	{
		Inv = Controller.Pawn.FindInventoryType(OrderEntry.ArtifactClass);
		
		if(Inv != None)
			Powerups(Inv).bActivatable = !OrderEntry.bNeverShow;
	}

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

function SaveCooldown(RPGArtifact A)
{
	local float TimeLeft;
	local ArtifactCooldown Cooldown;
	local int i;
	
	if(A.NextUseTime > Level.TimeSeconds)
	{
		TimeLeft = A.NextUseTime - Level.TimeSeconds;

		for(i = 0; i < SavedCooldown.Length; i++)
		{
			if(A.class == SavedCooldown[i].AClass)
			{
				SavedCooldown[i].TimeLeft = TimeLeft;
				return;
			}
		}
		
		Cooldown.AClass = A.class;
		Cooldown.TimeLeft = TimeLeft;
		SavedCooldown[SavedCooldown.Length] = Cooldown;
	}
}

function int GetSavedCooldown(class<RPGArtifact> AClass)
{
	local int i;
	
	for(i = 0; i < SavedCooldown.Length; i++)
	{
		if(AClass == SavedCooldown[i].AClass)
			return i;
	}
	
	return -1;
}

function ModifyArtifact(RPGArtifact A)
{
	local int i;
	
	ClientCheckArtifactClass(A.class);
	
	//Allow abilities to modify
	for(i = 0; i < Abilities.Length; i++)
	{
		if(Abilities[i].bAllowed)
			Abilities[i].ModifyArtifact(A);
	}
	
	//Apply saved cooldown
	i = GetSavedCooldown(A.class);
	if(i >= 0)
	{
		A.ForceCooldown(SavedCooldown[i].TimeLeft);
		SavedCooldown.Remove(i, 1);
	}
	
	/*
		If bNeverShow setting is used, make it non-selectable
		bActivatable is unused by the artifact itself, but Powerups / PlayerController
		use it to determine whether an item can be selected using NextItem and PrevItem
	*/
	i = FindOrderEntry(A.class);
	A.bActivatable = !(i >= 0 && ArtifactOrder[i].bNeverShow);
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
		OrderEntry.bNeverShow = false;
		
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
	local Inventory Inv;
	local int x;

	if(Level.NetMode != NM_DedicatedServer)
	{
		if(!bClientSetup)
			ClientSetup();
		
		if(SwitchToWeapon != None) //wait until it arrived in the inventory?
		{
			if(Controller.Pawn != None)
			{
				for(Inv = Controller.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
				{
					if(Inv == SwitchToWeapon)
					{
						PerformWeaponSwitch(SwitchToWeapon);
						SwitchToWeapon = None;
						break;
					}
				}
			}
		}
	}
	
	if(Controller == None)
	{
		Destroy();
		return;
	}
	
	CheckPlayerViewShake();
	
	if(Role == ROLE_Authority)
	{
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
				
				if(LastPawnWeapon != None && LastPawnWeapon.IsA('RPGWeapon'))
				{
					LastSelectedWeapon.WeaponClass = RPGWeapon(LastPawnWeapon).ModifiedWeapon.class;
					LastSelectedWeapon.ModifierClass = class<RPGWeapon>(LastPawnWeapon.class);
				}
				else
				{
					LastSelectedWeapon.WeaponClass = LastPawnWeapon.class;
					LastSelectedWeapon.ModifierClass = None;
				}
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

		//Clean mines
		x = 0;
		while(x < Mines.Length)
		{
			if(Mines[x] == None)
			{
				NumMines--;
				Mines.Remove(x, 1);
			}
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
	local FX_LevelUp Effect;
	local int Count;
	
	if(exp == 0)
		return;
	
	Log(RPGName @ "AwardExperience" @ exp);
	
	if(bGameEnded)
		return;
	
	if(PlayerController(Controller) != None && Level.Game.NumPlayers < class'MutTitanRPG'.default.MinHumanPlayersForExp)
		return;
	
	if(RPGMut.GameSettings.ExpScale > 0.0)
		exp *= RPGMut.GameSettings.ExpScale; //scale xp gain
	
	Experience = FMax(0.0, Experience + exp);
	ClientNotifyExpGain(exp);
	
	if(!RPGMut.bLevelCap || RPGLevel < RPGMut.Levels.Length) //don't allow levelup when max level was reached
	{
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
				Effect = Controller.Pawn.spawn(class'FX_LevelUp', Controller.Pawn);
				Effect.SetDrawScale(Controller.Pawn.CollisionRadius / Effect.CollisionRadius);
				Effect.Initialize();
			}
		}
		
		if(Count > 0)
		{
			if(Controller != None && Controller.Pawn != None)
				class'Util'.static.PlayLoudEnoughSound(Controller.Pawn, LevelUpSound);
		
			Level.Game.BroadCastLocalized(Self, class'GainLevelMessage', RPGLevel, PRI);
			ClientShowHint(LevelUpText);
			
			if(AIBuild != None)
				AIBuild.Build(Self);
			
			PlayerLevel.RPGLevel = RPGLevel;
			PlayerLevel.ExpNeeded = NeededExp;
		}
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
	local int i;

	for(i = 0; i < AllAbilities.Length; i++)
	{
		if(AllAbilities[i].bIsStat)
		{
			class'RPGMenu'.default.bStats = true;
			break;
		}
	}
	
	bClientSyncDone = true;
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
	
	ProcessGrantQueue(); //give weapons

	//Restore last selected weapon
	if(LastSelectedWeapon.WeaponClass != None)
	{
		for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(
				(LastSelectedWeapon.ModifierClass == None && Inv.class == LastSelectedWeapon.WeaponClass) ||
				(Inv.class == LastSelectedWeapon.ModifierClass && RPGWeapon(Inv).ModifiedWeapon.class == LastSelectedWeapon.WeaponClass)
			)
			{
				ClientSwitchToWeapon(Weapon(Inv));
				break;
			}
		}
	}

	if(bTeamChanged)
	{
		//respawning after team switch
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
}

function AddMine(ONSMineProjectile Mine)
{
	Mines[Mines.Length] = Mine;
	NumMines++;
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

function SetLevel(int NewLevel)
{
	Log(PRI.PlayerName $ " - SETLEVEL" @ NewLevel $ "!", 'TitanRPG');
	
	DataObject.LV = NewLevel;
	DataObject.PA = RPGMut.StartingStatPoints + RPGMut.PointsPerLevel * (NewLevel - 1);
	DataObject.XN = RPGMut.Levels[NewLevel];
	DataObject.XP = 0;
	DataObject.AB.Length = 0;
	DataObject.AL.Length = 0;
	DataObject.SaveConfig();
	
	Level.Game.BroadCastLocalized(Self, class'GainLevelMessage', NewLevel, PRI);
	
	Controller.Adrenaline = 0;
	if(Controller.Pawn != None)
		Controller.Pawn.Suicide();
	
	Destroy();
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

simulated function PerformWeaponSwitch(Weapon W)
{
	local Pawn Pawn;
	
	Pawn = Controller.Pawn;
	if(Pawn != None && !Pawn.IsA('Vehicle'))
	{
		if(W == None)
		{
			Log("Failed to switch weapon on client side - Weapon is NONE.", 'TitanRPG');
			return;
		}
			
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

simulated function ClientSwitchToWeapon(Weapon W)
{
	SwitchToWeapon = W;
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
}

function AddFavorite(class<Weapon> WeaponClass, class<RPGWeapon> ModifierClass)
{
	local FavoriteWeapon FW;
	local int i;
	
	for(i = 0; i < FavoriteWeapons.Length; i++)
	{
		if(FavoriteWeapons[i].WeaponClass == WeaponClass)
		{
			FavoriteWeapons[i].ModifierClass = ModifierClass;
			return;
		}
	}
	
	FW.WeaponClass = WeaponClass;
	FW.ModifierClass = ModifierClass;
	FavoriteWeapons[FavoriteWeapons.Length] = FW;
}

function RemoveFavorite(class<Weapon> WeaponClass)
{
	local int i;
	
	for(i = 0; i < FavoriteWeapons.Length; i++)
	{
		if(FavoriteWeapons[i].WeaponClass == WeaponClass)
		{
			FavoriteWeapons.Remove(i, 1);
			return;
		}
	}
}

function ServerFavoriteWeapon()
{
	local RPGWeapon RW;
	
	if(Controller == None || Controller.Pawn == None)
		return;
	
	RW = RPGWeapon(Controller.Pawn.Weapon);
	if(RW != None)
	{
		if(RW.bFavorite)
		{
			if(Controller.IsA('PlayerController'))
				PlayerController(Controller).ClientMessage(
					"Removed favorite:" @ RW.ModifiedWeapon.class @ "/" @ RW.class);
			RemoveFavorite(RW.ModifiedWeapon.class);
			RW.bFavorite = false;
		}
		else
		{
			if(Controller.IsA('PlayerController'))
				PlayerController(Controller).ClientMessage(
					"Added favorite:" @ RW.ModifiedWeapon.class @ "/" @ RW.class);

			AddFavorite(RW.ModifiedWeapon.class, RW.class);
			RW.bFavorite = true;
		}
	}
}

//grant queued weapons
function GrantQueuedWeapon(GrantWeapon GW)
{
	local RPGWeapon RW;

	RW = RPGWeapon(CreateWeapon(GW.WeaponClass, GW.ModifierClass));
	if(RW != None)
	{
		RW.SetModifier(GW.Modifier);
		RW.GiveTo(Controller.Pawn);
		RW.Identify(true); //TODO bNoUnidentified
		
		if(GW.Ammo[0] != 0) RW.SetAmmo(0, GW.Ammo[0]);
		if(GW.Ammo[1] != 0) RW.SetAmmo(1, GW.Ammo[1]);
	}
}

function ProcessGrantQueue()
{
	local int i;
	
	if(Controller.Pawn == None)
		return;
	
	if(GrantFavQueue.Length == 0 && GrantQueue.Length == 0)
		return;

	//grant favorite weapons first
	for(i = 0; i < GrantFavQueue.Length; i++)
		GrantQueuedWeapon(GrantFavQueue[i]);
	
	GrantFavQueue.Length = 0;
	
	//now try the others
	for(i = 0; i < GrantQueue.Length; i++)
		GrantQueuedWeapon(GrantQueue[i]);
	
	GrantQueue.Length = 0;
}

//Demonstrating the power of umake!
<?
	function printQueueFunc($queueName)
	{
?>
		for(i = 0; i < <? echo($queueName); ?>.Length; i++)
		{
			if(
				<? echo($queueName); ?>[i].WeaponClass == GW.WeaponClass &&
				<? echo($queueName); ?>[i].ModifierClass == GW.ModifierClass
			)
			{
				//override in queue weapon if this modifier is higher, otherwise discard
				if(GW.Modifier > <? echo($queueName); ?>[i].Modifier)
				{
					<? echo($queueName); ?>[i].Modifier = GW.Modifier;
					
					if(GW.Ammo[0] == -1 ||  GW.Ammo[0] > <? echo($queueName); ?>[i].Ammo[0])
						<? echo($queueName); ?>[i].Ammo[0] = GW.Ammo[0];

					if(GW.Ammo[1] == -1 ||  GW.Ammo[1] > <? echo($queueName); ?>[i].Ammo[1])
						<? echo($queueName); ?>[i].Ammo[1] = GW.Ammo[1];
				}
				return;
			}
		}
		
		<? echo($queueName); ?>[<? echo($queueName); ?>.Length] = GW;
<?
	}
?>

//Add to weapon grant queue
function QueueWeapon(class<Weapon> WeaponClass, class<RPGWeapon> ModifierClass, int Modifier, optional int Ammo1, optional int Ammo2)
{
	local int i;
	local GrantWeapon GW;
	
	GW.WeaponClass = WeaponClass;
	GW.ModifierClass = ModifierClass;
	GW.Modifier = Modifier;
	GW.Ammo[0] = Ammo1;
	GW.Ammo[1] = Ammo2;
	
	if(IsFavorite(WeaponClass, ModifierClass))
	{
		<? printQueueFunc(GrantFavQueue); ?>
	}
	else
	{
		<? printQueueFunc(GrantQueue); ?>
	}
}

//Find out whether a Weapon/Modifier combination is a favorite
function bool IsFavorite(class<Weapon> WeaponClass, class<RPGWeapon> ModifierClass)
{
	local int i;
	
	for(i = 0; i < FavoriteWeapons.Length; i++)
	{
		if(
			WeaponClass == FavoriteWeapons[i].WeaponClass &&
			ModifierClass == FavoriteWeapons[i].ModifierClass
		)
		{
			return true;
		}
	}
	return false;
}

//Find whether the current player already holds a favorite for the current weapon class
function bool WantsWeaponType(class<Weapon> WeaponClass)
{
	local RPGWeapon RW;
	local Inventory Inv;
	
	if(Controller == None || Controller.Pawn == None)
		return false;
	
	if(FavoriteWeapons.Length == 0)
		return true;

	//find whether the already holds a favorite
	for(Inv = Controller.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		RW = RPGWeapon(Inv);
		if(
			RW != None &&
			RW.ModifiedWeapon.class == WeaponClass &&
			RW.bFavorite
		)
		{
			return false; //no thanks
		}
	}
	
	return true;
}

//Create and enchant a weapon (does not give it to the Pawn yet!)
function Weapon CreateWeapon(class<Weapon> WeaponClass, optional class<RPGWeapon> ModifierClass, optional Pickup Pickup)
{
	local string NewWeaponClassName;
	local Weapon W;
	
	if(Controller == None || Controller.Pawn == None)
		return None;
	
	NewWeaponClassName = Level.Game.BaseMutator.GetInventoryClassOverride(string(WeaponClass));
	if(!(NewWeaponClassName ~= string(WeaponClass)))
		WeaponClass = class<Weapon>(DynamicLoadObject(NewWeaponClassName, class'Class'));
	
	if(WeaponClass != None && WantsWeaponType(WeaponClass))
	{
		W = Spawn(WeaponClass, Controller.Pawn);
	
		if(ModifierClass != None && W != None)
			return EnchantWeapon(W, ModifierClass);
		else
			return W;
	}
	
	return None;
}

//Enchant a weapon with the given magic and level (does not give it to the Pawn yet!)
function RPGWeapon EnchantWeapon(Weapon W, class<RPGWeapon> ModifierClass)
{
	local class<Weapon> WClass;
	local RPGWeapon RW;

	if(Controller == None || Controller.Pawn == None)
		return None;

	RW = RPGWeapon(W);
	if(RW != None)
	{
		WClass = RW.ModifiedWeapon.class;
		W = Spawn(WClass, Controller.Pawn);
		
		if(W != None)
		{
			RW.DetachFromPawn(Controller.Pawn);
			RW.Destroy();
		}
		else
		{
			return None;
		}
	}

	RW = Spawn(ModifierClass, Controller.Pawn);
	
	if(RW != None)
		RW.SetModifiedWeapon(W, false);
	
	return RW;
}

defaultproperties
{
	AmmoMax=0
	WeaponSpeed=0
	HealingExpMultiplier=0 //gotten from RPGRules

	LevelUpSound=Sound'<? echo($packageName); ?>.SoundEffects.LevelUp'

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
