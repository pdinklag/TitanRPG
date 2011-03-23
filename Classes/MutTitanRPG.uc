class MutTitanRPG extends Mutator
	config(TitanRPG);

//Import resources
#exec OBJ LOAD FILE=Resources/TitanRPG_rc.u PACKAGE=<? echo($packageName); ?>

//Saving
var config array<string> IgnoreNameTag;

var config int SaveDuringGameInterval;
var float NextSaveTime;
var bool bJustSaved;

var localized string SavingDataText, SavedDataText;

//General
var config bool bAllowCheats;
var config int StartingLevel, StartingStatPoints;
var config int PointsPerLevel;
var config int MinHumanPlayersForExp;
var config array<int> Levels;
var config float LevelDiffExpGainDiv; //divisor to extra experience from defeating someone of higher level (a value of 1 results in level difference squared EXP)
var config int MaxLevelupEffectStacking;
var config array<class<RPGAbility> > Abilities;
var config array<class<RPGAbility> > Stats;
var config array<class<RPGArtifact> > Artifacts; //artifacts that are displayed in the HUD

var localized string SecondTextSingular, SecondTextPlural;

var config array<class<RPGArtifact> > DefaultArtifacts; //artifacts that players spawn with
var config array<class<Combo> > Combos; //additional combos to enable for players

var config array<class<Weapon> > DisallowModifiersFor; //these weapons can not be modified

//OLTeamGames support
var bool bOLTeamGames;

//Game-type specific settings
var RPGGameSettings GameSettings;

//Rebuild instead of Reset
var config bool bAllowRebuild;
var config int RebuildCost;
var config int RebuildMaxLevelLoss;

//Modifiers
//var config float WeaponModifierChance; //moved to RPGGameSettings
struct WeaponModifier
{
	var class<RPGWeapon> WeaponClass;
	var int Chance;
};

var config array<WeaponModifier> WeaponModifiers;
var int TotalModifierChance;

//Available status icons
var config array<class<RPGStatusIcon> > StatusIcons;

//Stuff
var config bool bAllowSuperWeaponReplenish; //allow RPGWeapon::FillToInitialAmmo() on superweapons
var config array<class<Ammunition> > SuperAmmoClasses;

var config int MaxDrones, StartingDrones;
var config int MaxMonsters; //minimum MaxMonsters per player...
var config int MaxTurrets; //minimum MaxTurrets per player...
var config int MaxMines; //minimum MaxMines per player...

//admin commands
var config array<String> AdminGUID;

//CTF Assist
var CTFFlag RedFlag, BlueFlag;
var RPGAssistInfo RedInfo, BlueInfo;

//INIT stuff
var bool bAddedAssistInfo;
var bool bGameStarted;

//Instance
static final function MutTitanRPG Instance(LevelInfo Level)
{
	local Mutator Mut;
	
	if(Level.Game != None)
	{
		for(Mut = Level.Game.BaseMutator; Mut != None; Mut = Mut.NextMutator)
		{
			if(Mut.IsA('MutTitanRPG'))
				return MutTitanRPG(Mut);
		}
	}
	return None;
}

//returns true if the specified ammo belongs to a weapon that we consider a superweapon
final function bool IsSuperWeaponAmmo(class<Ammunition> AmmoClass)
{
	return (AmmoClass.default.MaxAmmo < 5 || class'Util'.static.InArray(AmmoClass, SuperAmmoClasses) >= 0);
}

final function class<RPGAbility> ResolveAbility(string Alias)
{
	local class<RPGAbility> Loaded;
	local int i;

	Alias = Repl(Alias, "#", "Ability");
	for(i = 0; i < Abilities.Length; i++)
	{
		if(string(Abilities[i].Name) ~= Alias)
			return Abilities[i];
	}
	
	//Fallback, for seamless transitions from 1.5 or earlier
	Loaded = class<RPGAbility>(DynamicLoadObject("<? echo($packageName); ?>.Ability" $ Alias, class'Class'));

	if(Loaded == None)
		Log("WARNING: Could not resolve ability alias:" @ Alias, 'TitanRPG');

	return Loaded;
}

static final function string GetAbilityAlias(class<RPGAbility> AbilityClass)
{
	return Repl(string(AbilityClass.Name), "Ability", "#");
}

static final function string GetGameSettingsName(GameInfo Game)
{
	return string(Game.class);
}

final function string ProcessPlayerName(RPGPlayerReplicationInfo RPRI)
{
	local string PlayerName;
	local int x, i;
	
	PlayerName = RPRI.PRI.PlayerName;
	for(x = 0; x < default.IgnoreNameTag.Length; x++)
	{
		for(
			i = InStr(PlayerName, default.IgnoreNameTag[x]);
			i >= 0;
			i = InStr(PlayerName, default.IgnoreNameTag[x]))
		{
			if(i > 0)
				PlayerName = Mid(PlayerName, i);
				
			if(Len(PlayerName) > Len(default.IgnoreNameTag[x]))
				PlayerName = Mid(PlayerName, Len(default.IgnoreNameTag[x]));
		}
	}
	
	return PlayerName;
}

event PreBeginPlay()
{
	local int i, x;
	local DruidsOldWeaponHolder WeaponHolder;

	if(Role == ROLE_Authority && Level.Game.ResetCountDown == 2)
	{
		foreach DynamicActors(class'DruidsOldWeaponHolder', WeaponHolder)
			WeaponHolder.Destroy();
	}
	
	//OLTeamGames support
	bOLTeamGames = Level.Game.IsA('OLTeamGame');

	//Register stats as abilities internally, makes replication easier
	for(i = 0; i < Stats.Length; i++)
		Abilities[Abilities.Length] = Stats[i];
	
	//Check abilities
	x = 0;
	i = 0;
	while(i < Abilities.Length)
	{
		x++;
	
		if(Abilities[i] == None)
		{
			Log("WARNING: Entry #" @ x @ "in the Abilities list doesn't resolve to a valid ability class!", 'TitanRPG');
			Abilities.Remove(i, 1);
			continue;
		}
		else
		{
			i++;
		}
	}
	
	Super.PreBeginPlay();

	class'XGame.xPawn'.default.ControllerClass = class'RPGBot';
	
	if(Level.Game.PlayerControllerClassName ~= "XGame.xPlayer") //don't replace another mod's xPlayer replacement
		Level.Game.PlayerControllerClassName = "<? echo($packageName); ?>.TitanPlayerController";

	//Find specific settings for this gametype
	GameSettings = new(None, GetGameSettingsName(Level.Game)) class'RPGGameSettings';
	
	DeathMatch(Level.Game).bAllowTrans = GameSettings.bAllowTrans;
	DeathMatch(Level.Game).bAllowVehicles = GameSettings.bAllowVehicles;
	
	if(Level.Game.bEnableStatLogging)
		Level.Game.Spawn(class'RPGGameStats');
}

event PostBeginPlay()
{
	local RPGRules Rules;
	local HealableDamageGameRules HealRules;
	local RPGReplicationInfo RRI;
	local int x;
	
	//RPG Rules
	Rules = Spawn(class'RPGRules');
	Rules.RPGMut = self;
	Rules.PointsPerLevel = PointsPerLevel;
	Rules.LevelDiffExpGainDiv = LevelDiffExpGainDiv;
	
	Rules.NextGameRules = Level.Game.GameRulesModifiers;
	Level.Game.GameRulesModifiers = Rules;
	
	//Healable damage rules
	HealRules = Spawn(class'HealableDamageGameRules');
	HealRules.NextGameRules = Rules.NextGameRules;
	Rules.NextGameRules = HealRules;

	//Modifiers
	for(x = 0; x < WeaponModifiers.Length; x++)
		TotalModifierChance += WeaponModifiers[x].Chance;

	//Artifacts
	if(GameSettings.bAllowArtifacts)
		Spawn(class'RPGArtifactManager').Initialize(Self);
	
	//Save
	if(SaveDuringGameInterval > 0)
	{
		NextSaveTime = Level.TimeSeconds + float(SaveDuringGameInterval);
		SetTimer(SaveDuringGameInterval, true);
	}

	//Stuff
	if(StartingLevel < 1)
		StartingLevel = 1;

	//RPG replication info
	RRI = Spawn(class'RPGReplicationInfo');

	//Abilities
	RRI.NumAbilities = Abilities.Length;

	//Artifacts
	if(Artifacts.Length > RRI.MAX_ARTIFACTS)
		Log("WARNING:" @ Artifacts.Length @ "artifact classes were configured, but only" @ RRI.MAX_ARTIFACTS @ "are supported!", 'TitanRPG');
	
	for(x = 0; x < RRI.MAX_ARTIFACTS && x < Artifacts.Length; x++)
		RRI.Artifacts[x] = Artifacts[x];

	//Super
	Super.PostBeginPlay();
}

function string GetInventoryClassOverride(string InventoryClassName)
{
	InventoryClassName = Super.GetInventoryClassOverride(InventoryClassName);
	
	//OLTeamGames doesn't do this, but I want explicit support for it, so here we go
	if(bOLTeamGames)
	{
		if(InventoryClassName ~= "XWeapons.ShockRifle")
			return "OLTeamGames.OLTeamsShockRifle";
		else if(InventoryClassName ~= "Onslaught.ONSGrenadeLauncher")
			return "OLTeamGames.OLTeamsONSGrenadeLauncher";
		else if(InventoryClassName ~= "XWeapons.TransLauncher")
			return "OLTeamGames.OLTeamsTranslauncher";
	}

	if(InventoryClassName ~= "XWeapons.RocketLauncher")
		return "<? echo($packageName); ?>.RPGRocketLauncher";
	else if(InventoryClassName ~= "XWeapons.ShieldGun" || InventoryClassName ~= "OLTeamGames.OLTeamsShieldGun")
		return "<? echo($packageName); ?>.RPGShieldGun";
	else if(InventoryClassName ~= "XWeapons.LinkGun" || InventoryClassName ~= "OLTeamGames.OLTeamsLinkGun")
		return "<? echo($packageName); ?>.RPGLinkGun";
	else if(InventoryClassName ~= "Onslaught.ONSMineLayer" || InventoryClassName ~= "OLTeamGames.OLTeamsONSMineLayer")
		return "<? echo($packageName); ?>.RPGMineLayer";
	else if(InventoryClassName ~= "XWeapons.BallLauncher")
		return "<? echo($packageName); ?>.RPGBallLauncher";

	return InventoryClassName;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local int i;
	local RPGWeaponPickup RPGPickup;
	local WeaponLocker Locker;
	local RPGWeaponLocker RPGLocker;
	local Weapon W;
	local string ClassName, NewClassName;

	if(Other == None)
		return true;
	
	//Disbale artifacts (game settings)
	if(Other.IsA('RPGArtifact') && !GameSettings.AllowArtifact(class<RPGArtifact>(Other.class)))
	{
    	bSuperRelevant = 0;
		return false;
    }
	
	if(Other.IsA('RPGArtifactPickup') && !GameSettings.AllowArtifact(class<RPGArtifact>(RPGArtifactPickup(Other).InventoryType)))
	{
    	bSuperRelevant = 0;
		return false;
    }
	
	//Required Equipment
	if(Other.IsA('UnrealPawn'))
	{
		//Monster fake weapon (for NetDamage to be called)
		if(Other.IsA('Monster'))
			Spawn(class'FakeMonsterWeapon', Other).GiveTo(Pawn(Other));
	
		for(i = 0; i < 16; i++)
			UnrealPawn(Other).RequiredEquipment[i] = GetInventoryClassOverride(UnrealPawn(Other).RequiredEquipment[i]);
		
		return true;
	}
	
	//Ball Launcher
	if(Other.IsA('xBombFlag'))
	{
		xBombFlag(Other).BombLauncherClassName = "<? echo($packageName); ?>.RPGBallLauncher";
		return true;
	}
	
	//Max ammo hack (will be overridden by the RPRI)
	if(Other.IsA('Ammunition') && !Other.IsA('ShieldAmmo'))
	{
		Ammunition(Other).MaxAmmo = 999;
		return true;
	}
	
	//Replace weapon pickup
	if(Other.IsA('WeaponPickup') && !Other.IsA('RPGWeaponPickup') && !Other.IsA('TransPickup'))
	{
		RPGPickup = RPGWeaponPickup(ReplaceWithActor(Other, "<? echo($packageName); ?>.RPGWeaponPickup"));
		if(RPGPickup != None)
		{
			RPGPickup.FindPickupBase();
			RPGPickup.GetPropertiesFrom(class<WeaponPickup>(Other.class));
		}
		return false;
	}
	
	//Replace weapon locker (TODO: only if magic weapon chance > 0 ???)
	if(Other.IsA('WeaponLocker') && !Other.IsA('RPGWeaponLocker'))
	{
		Locker = WeaponLocker(Other);
		RPGLocker = RPGWeaponLocker(ReplaceWithActor(Other, "<? echo($packageName); ?>.RPGWeaponLocker"));
		
		if(RPGLocker != None)
		{
			RPGLocker.SetLocation(Locker.Location);
			RPGLocker.ReplacedLocker = Locker;
			Locker.GotoState('Disabled');
		}

		for(i = 0; i < Locker.Weapons.length; i++)
		{
			if(Locker.Weapons[i].WeaponClass != None)
			{
				ClassName = String(Locker.Weapons[i].WeaponClass);
				NewClassName = GetInventoryClassOverride(ClassName);
				
				if(!(NewClassName ~= ClassName))
					Locker.Weapons[i].WeaponClass = class<Weapon>(DynamicLoadObject(NewClassName, class'Class'));
			}
		}
		return true;
	}
	
	//Replace weapon base weapons
	if(Other.IsA('xWeaponBase'))
	{
		ClassName = string(xWeaponBase(Other).WeaponType);
		NewClassName = GetInventoryClassOverride(ClassName);

		if(!(NewClassName ~= ClassName))
			xWeaponBase(Other).WeaponType = class<Weapon>(DynamicLoadObject(NewClassName, class'Class'));
		
		return true;
	}
	
	//Weapon
	if(Other.IsA('Weapon'))
	{
		W = Weapon(Other);
	
		//WeaponFire
		for(i = 0; i < W.NUM_FIRE_MODES; i++)
		{
			if(W.FireModeClass[i] != None)
			{
				if(W.FireModeClass[i] == class'PainterFire')
					W.FireModeClass[i] = class'RPGPainterFire';
				else if (W.FireModeClass[i] == class'ONSPainterFire')
					W.FireModeClass[i] = class'RPGONSPainterFire';
				else if (W.FireModeClass[i] == class'ONSAVRiLFire')
					W.FireModeClass[i] = class'RPGONSAVRiLFire';
				else if(W.FireModeClass[i] == class'TransFire' || string(W.FireModeClass[i]) ~= "OLTeamGames.OLTeamsTransFire")
					W.FireModeClass[i] = class'RPGTransFire';
			}
		}
		
		//Hack for AmmoMax (from UT2004RPG, not sure exactly what this is needed for)
		if(GameSettings.WeaponModifierChance <= 0)
			W.bNoAmmoInstances = false;
		
		return true;
	}
	
	//Force adrenaline on if artifacts are enabled
	if(Other.IsA('Controller'))
	{
		if(
			class'RPGArtifactManager'.default.SpawnDelay > 0 &&
			class'RPGArtifactManager'.default.MaxArtifacts > 0 &&
			class'RPGArtifactManager'.default.AvailableArtifacts.Length > 0
		)
		{
			Controller(Other).bAdrenalineEnabled = true;
		}
		return true;
	}
	
	return true;
}

//Replace an actor and then return the new actor
function Actor ReplaceWithActor(actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if ( aClassName == "" )
		return None;

	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if ( aClass != None )
		A = Spawn(aClass,Other.Owner,Other.tag,Other.Location, Other.Rotation);
	if ( Other.IsA('Pickup') )
	{
		if ( Pickup(Other).MyMarker != None )
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if ( Pickup(A) != None )
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location
					+ (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		else if ( A.IsA('Pickup') )
			Pickup(A).Respawntime = 0.0;
	}
	if ( A != None )
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return A;
	}
	return None;
}

event Tick(float dt)
{
	local Weapon W;
	local Projectile Proj;
	local CTFFlag F;
	
	//If stats are disabled, create the game stats override here
	if(!bGameStarted && !Level.Game.bWaitingToStartMatch)
	{
		bGameStarted = true;
		
		if(!Level.Game.bEnableStatLogging)
			Level.Game.Spawn(class'RPGGameStats');
	}
	
	//AssistInfo
	if(!bAddedAssistInfo)
	{
		if(Level.Game.GameReplicationInfo.bMatchHasBegun) //Match started!
		{
			foreach AllActors(class'CTFFlag', F) //find flags.
			{
				if(F.TeamNum == 1)
					BlueFlag = F;
				else
					RedFlag = F;
			}

			if(RedFlag != None && BlueFlag != None) //Spawn Infos and set variables in those.
			{
				RedInfo = Spawn(class'RPGAssistInfo', RedFlag);
				BlueInfo = Spawn(class'RPGAssistInfo', BlueFlag);
				RedInfo.EnemyTeamInfo  = BlueFlag.Team;
				BlueInfo.EnemyTeamInfo = RedFlag.Team;
				RedInfo.EnemyTeamScore  = BlueFlag.Team.Score;
				BlueInfo.EnemyTeamScore = RedFlag.Team.Score;
				bAddedAssistInfo = true;
			}
		}
	}
	
	//Projectiles
	foreach DynamicActors(class'Projectile', Proj)
	{
		if(Proj.Tag == Proj.class.Name && Proj.Instigator != None)
		{
			W = Proj.Instigator.Weapon;
			
			if(W != None && W.IsA('RPGWeapon'))
				RPGWeapon(Proj.Instigator.Weapon).ModifyProjectile(Proj);

			Proj.Tag = 'Processed';
		}
	}
}

function RPGPlayerReplicationInfo CheckRPRI(Controller C)
{
	local int x, i;
	local RPGPlayerReplicationInfo RPRI;

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
	if(RPRI == None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.CreateFor(C);
		ValidateData(RPRI);
		
		//Combos
		if(xPlayer(C) != None)
		{
			for(x = 0; x < Combos.Length; x++)
			{
				for(i = 0; i < 16 && xPlayer(C).ComboNameList[i] != ""; i++)
				{
					if(xPlayer(C).ComboNameList[i] ~= string(Combos[x]))
						i = 16; //break;
				}
				
				if(i < 16)
				{
					xPlayer(C).ComboNameList[i] = string(Combos[x]);
					xPlayer(C).ClientReceiveCombo(string(Combos[x]));
				}
			}
		}
	}
	return RPRI;
}

function ReplaceBotController(Pawn Other)
{
	//TODO: how???

	/*
	local Controller OldController;
	local UnrealTeamInfo Team;
	local string RosterEntry;
	local Bot Bot;
	local DeathMatch Game;

	Game = DeathMatch(Level.Game);
	OldController = Other.Controller;
	
	if(OldController.IsA('RPGBot'))
		return;
	
	Log("Replacing bot for" @ OldController.GetHumanReadableName() $ ", old controller class is" @ string(OldController.class), 'TitanRPG');
	
	Team = UnrealTeamInfo(Other.PlayerReplicationInfo.Team);
	RosterEntry = Other.PlayerReplicationInfo.PlayerName;
	
	OldController.UnPossess();
	//OldController.Destroy();
	
	Bot = Spawn(class'RPGBot');
	Game.AdjustedDifficulty += 2;
	Game.InitializeBot(Bot, Team, class'xRosterEntry'.static.CreateRosterEntryCharacter(RosterEntry));
	Game.AdjustedDifficulty -= 2;
	Bot.bInitLifeMessage = true;
	
	Bot.Possess(Other);
	*/
}

function ModifyPlayer(Pawn Other)
{
	local RPGPlayerReplicationInfo RPRI;
	local int x;
	local Inventory Inv;
	local array<Weapon> StartingWeapons;
	local class<Weapon> StartingWeaponClass;
	local RPGWeapon MagicWeapon;
	
	Super.ModifyPlayer(Other);

	if(Other.Controller == None || !Other.Controller.bIsPlayer)
		return;
	
	//Invasion forces a specific bot class, so we need to replace it afterwards
	if(!Other.Controller.IsA('RPGBot') && (Other.Controller.IsA('InvasionBot') || Other.Controller.IsA('InvasionProBot')))
		ReplaceBotController(Other);
	
	RPRI = CheckRPRI(Other.Controller);
	if(RPRI == None)
	{
		Warn("No RPRI for " $ Other.GetHumanReadableName() $ "!");
		return;
	}

	if(GameSettings.bAllowTrans)
	{
		class'Util'.static.GiveInventory(Other,
			class<Inventory>(DynamicLoadObject(
				Level.Game.BaseMutator.GetInventoryClassOverride("XWeapons.TransLauncher"), class'Class')));
	}
	
	if(GameSettings.bAllowArtifacts)
	{
		for(x = 0; x < DefaultArtifacts.Length; x++)
			class'Util'.static.GiveInventory(Other, DefaultArtifacts[x]);
	}

	if(GameSettings.WeaponModifierChance > 0)
	{
		x = 0;
		for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(Weapon(Inv) != None)
			{
				if(RPGWeapon(Inv) == None)
					StartingWeapons[StartingWeapons.length] = Weapon(Inv);
			}
			
			if(++x > 1000)
				break;
		}

		for(x = 0; x < StartingWeapons.length; x++)
		{
			StartingWeaponClass = StartingWeapons[x].Class;
			
			// don't affect the translocator because it breaks bots
			if(!ClassIsChildOf(StartingWeaponClass, class'TransLauncher'))
			{
				StartingWeapons[x].Destroy();
				if (GameSettings.bMagicalStartingWeapons)
					MagicWeapon = Spawn(GetRandomWeaponModifier(StartingWeaponClass, Other), Other,,, rot(0,0,0));
				else
					MagicWeapon = Spawn(class'RPGWeapon', Other,,, rot(0,0,0));
				
				MagicWeapon.Generate(None);
				MagicWeapon.SetModifiedWeapon(spawn(StartingWeaponClass,Other,,,rot(0,0,0)), GameSettings.bNoUnidentified);
				MagicWeapon.GiveTo(Other);
			}
		}
		Other.Controller.ClientSwitchToBestWeapon();
	}

	if(RPGWeapon(Other.Weapon) != None)
		RPGWeapon(Other.Weapon).StartEffect();

	//set pawn's properties
	RPRI.ModifyPlayer(Other);

	//Spawn drones
	if(StartingDrones > MaxDrones)
		Warn("StartingDrones exceeds MaxDrones!");

	for(x = 0; x < StartingDrones; x++)
		class'Drone'.static.SpawnFor(Other);
}

function EndGame()
{
	local Controller C;
	local RPGPlayerReplicationInfo RPRI;
	
	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if(C.bIsPlayer && C.PlayerReplicationInfo != None)
		{
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
			if(RPRI != None)
				RPRI.GameEnded();
		}
	}
	
	/*
		Saving the player data causes a hangup if the server database is large,
		therefore put it back one second to avoid the "end game lag" effect  -pd
	*/
	SetTimer(1.0, false);
}

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	local Inventory Inv;
	local int i;
	local array<RPGArtifact> MyArtifacts;
	local VehicleMagicInv VMInv;
	local RPGPlayerReplicationInfo RPRI;
	
	//disable spawn protection for the vehicle!!
	if(Level.TimeSeconds - V.SpawnTime < DeathMatch(Level.Game).SpawnProtectionTime)
		V.SpawnTime = Level.TimeSeconds - DeathMatch(Level.Game).SpawnProtectionTime - 1;

	//modify vehicle
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(V.Controller);
	if (RPRI != None)
		RPRI.DriverEnteredVehicle(V, P);

	//move all artifacts from driver to vehicle, so player can still use them
	for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(RPGArtifact(Inv) != None)
			MyArtifacts[MyArtifacts.length] = RPGArtifact(Inv);
	}
	
	//stop the weapon magic effect, if present (DetachFromPawn does not get called)
	if(RPGWeapon(P.Weapon) != None)
		RPGWeapon(P.Weapon).StopEffect();

	//hack - temporarily give the pawn its Controller back because RPGArtifact.Activate() needs it
	P.Controller = V.Controller;
	for (i = 0; i < MyArtifacts.length; i++)
	{
		if(MyArtifacts[i].bActive)
		{
			//turn it off first
			MyArtifacts[i].ActivatedTime = 0.f; //force it to allow deactivation
			MyArtifacts[i].Activate();
		}
		
		if(MyArtifacts[i] == P.SelectedItem)
			V.SelectedItem = MyArtifacts[i];
			
		P.DeleteInventory(MyArtifacts[i]);
		MyArtifacts[i].GiveTo(V);
	}
	P.Controller = None;

	//apply vehicle magic
	VMInv = VehicleMagicInv(P.FindInventoryType(class'VehicleMagicInv'));
	if(VMInv != None && VMInv.VMClass != None)
		VMInv.VMClass.static.ApplyTo(V);

	Super.DriverEnteredVehicle(V, P);
}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
	local Inventory Inv;
	local array<RPGArtifact> MyArtifacts;
	local int i;
	local VehicleMagic VM;
	local RPGPlayerReplicationInfo RPRI;
	
	//Disable any vehicle magic -pd
	VM = class'VehicleMagic'.static.FindFor(V);
	if(VM != None)
		VM.Destroy();

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(P.Controller);
	if(RPRI != None)
		RPRI.DriverLeftVehicle(V, P);

	//move all artifacts from vehicle to driver
	for(Inv = V.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(RPGArtifact(Inv) != None)
			MyArtifacts[MyArtifacts.length] = RPGArtifact(Inv);
	}

	for(i = 0; i < MyArtifacts.length; i++)
	{
		if(MyArtifacts[i].bActive)
		{
			//hack - temporarily give the vehicle its Controller back because RPGArtifact::Activate() needs it
			V.Controller = P.Controller;
			MyArtifacts[i].ActivatedTime = 0.f; //force it to allow deactivation
			MyArtifacts[i].Activate();
			V.Controller = None;
		}
		
		if(MyArtifacts[i] == V.SelectedItem)
			P.SelectedItem = MyArtifacts[i];

		V.DeleteInventory(MyArtifacts[i]);
		MyArtifacts[i].GiveTo(P);
	}

	Super.DriverLeftVehicle(V, P);
}

function bool CanEnterVehicle(Vehicle V, Pawn P)
{
	local RPGPlayerReplicationInfo RPRI;
	local int i;
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(P.Controller);
	if(RPRI != None)
	{
		for(i = 0; i < RPRI.Abilities.length; i++)
		{
			if(RPRI.Abilities[i].bAllowed)
			{
				if(!RPRI.Abilities[i].CanEnterVehicle(V))
					return false;
			}
		}
	}
	
	return Super.CanEnterVehicle(V, P);
}

function bool CanLeaveVehicle(Vehicle V, Pawn P)
{
	return Super.CanLeaveVehicle(V, P);
}

//Check the player data at the given index for errors (too many/not enough stat points, invalid abilities)
//Converts the data by giving or taking the appropriate number of stat points and refunding points for abilities bought that are no longer allowed
//This allows the server owner to change points per level settings and/or the abilities allowed and have it affect already created players properly
function ValidateData(RPGPlayerReplicationInfo RPRI)
{
	local int ShouldBe, TotalPoints, x, y;

	for(x = 0; x < RPRI.Abilities.length; x++)
	{
		if(class'Util'.static.InArray(RPRI.Abilities[x].class, Abilities) >= 0)
		{
			for(y = 0; y < RPRI.Abilities[x].AbilityLevel; y++)
				TotalPoints += RPRI.Abilities[x].CostForNextLevel(y);
		}
		else
		{
			for(y = 0; y < RPRI.Abilities[x].AbilityLevel; y++)
				RPRI.PointsAvailable += RPRI.Abilities[x].CostForNextLevel(y);
				
			Log("Ability" @ RPRI.Abilities[x] @ "was in" @ RPRI.RPGName $ "'s data but is not an available ability - removed (stat points refunded)", 'TitanRPG');
			RPRI.Abilities.Remove(x, 1);
			x--;
		}
	}
	
	TotalPoints += RPRI.PointsAvailable;
	
	ShouldBe = StartingStatPoints + ((RPRI.RPGLevel - 1) * PointsPerLevel);
	if(TotalPoints != ShouldBe)
	{
		Warn(RPRI.RPGName $ " had " $ TotalPoints $ " total stat points at Level " $ RPRI.RPGLevel $ ", should be " $ ShouldBe $ ", PointsAvailable changed by " $ (ShouldBe - TotalPoints) $ " to compensate.");
		Log("Here's a breakdown:", 'TitanRPG');
		Log(RPRI.PointsAvailable $ " (Points available)", 'TitanRPG');
		for (x = 0; x < RPRI.Abilities.Length; x++)
		{
			for(y = 0; y < RPRI.Abilities[x].AbilityLevel; y++)
				Log("+ " $ RPRI.Abilities[x].CostForNextLevel(y) $ " (" $ RPRI.Abilities[x].default.AbilityName $ " " $ (y + 1) $ ")", 'TitanRPG');
		}
		Log("= " $ TotalPoints, 'TitanRPG');
		Log("", 'TitanRPG');
		
		RPRI.PointsAvailable += ShouldBe - TotalPoints;
	}
}

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other, optional bool bForceModifier)
{
	local int x, Chance;

	if(bForceModifier || FRand() < GameSettings.WeaponModifierChance)
	{
		Chance = Rand(TotalModifierChance);
		for (x = 0; x < WeaponModifiers.Length; x++)
		{
			Chance -= WeaponModifiers[x].Chance;
			if (Chance < 0 && WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
				return WeaponModifiers[x].WeaponClass;
		}
	}
	return class'RPGWeapon';
}

function NotifyLogout(Controller Exiting)
{
	local RPGPlayerReplicationInfo RPRI;
	
	if(Level.Game.bGameRestarted)
		return;

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Exiting);
	if(RPRI == None)
		return;

	RPRI.SaveData();
	RPRI.Destroy();
}

function Timer()
{
	SaveData();
	NextSaveTime = Level.TimeSeconds + float(SaveDuringGameInterval);
}

function SaveData()
{
	local Controller C;
	local RPGPlayerReplicationInfo RPRI;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if(C.bIsPlayer)
		{
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
			if(RPRI != None)
				RPRI.SaveData();
		}
	}
	
	Log("TitanRPG player data has been saved!", 'TitanRPG');
}

function SwitchBuild(RPGPlayerReplicationInfo RPRI, string NewBuild)
{
	local Inventory Inv;
	local DruidsOldWeaponHolder OldWeaponHolder;
	local Controller C;
	local PlayerReplicationInfo PRI;

	C = RPRI.Controller;
	PRI = RPRI.PRI;

	if(NewBuild == "" || RPRI.RPGName ~= NewBuild)
		return;

	RPRI.SaveData();

	if(PRI.PlayerName != NewBuild && PlayerController(C) != None)
		RPRI.ClientSetName(NewBuild);

	if(C.Pawn != None)
	{
		Inv = C.Pawn.Inventory;
		while(Inv != None)
		{
			Inv = Inv.Inventory;
			Inv.Destroy();
		}
		
		C.Pawn.Suicide(); //DIE!!!
	}

	C.Adrenaline = 0;

	//Don't allow Denial to keep your weapon
    foreach C.DynamicActors(class'DruidsOldWeaponHolder', OldWeaponHolder)
	{
        if(OldWeaponHolder.Owner == C)
			OldWeaponHolder.Destroy();
	}
	
	//Reset score
	RPRI.PRI.Score = 0.f;
	
	//"reconnect"
	RPRI.Destroy();
}

function ServerTraveling(string URL, bool bItems)
{
	local int i;
	local LoopDetection A, B;
	local FileLog FLog;
	local Object X;
	local array<Object> Ref;
	local int TravelTimeDiff;

	A = new(None, "TitanRPG") class'LoopDetection';
	B = new(None, "Temp") class'LoopDetection';
	B.FromCurrent(Level);
	
	if(A.IsInfoValid())
	{
		TravelTimeDiff = B.ToSeconds() - A.ToSeconds();
		Log("DEBUG: Last travel was" @ TravelTimeDiff @ "seconds ago (" $ A.Format() $ ").", 'TitanRPG');
		
		if(TravelTimeDiff < 5 && TravelTimeDiff > 0)
		{
			Log("=> LOOP DETECTED", 'TitanRPG');
			
			Log("", 'TitanRPG');
			Log("DEBUG: Testing file output to 'loop.log'...", 'TitanRPG');
			FLog = Spawn(class'FileLog');
			FLog.OpenLog("loop.log",, true);
			FLog.Logf("Testing file output - if this file is not in UserLogs, something's seriously wrong...");
			FLog.CloseLog();
			FLog.Destroy();
			Flog = None;
			
			Log("", 'TitanRPG');
			Log("DEBUG: Trying to obtain an object from an unused package (class'OLTeamGames.OLTeamGame')...", 'TitanRPG');
			X = DynamicLoadObject("OLTeamGames.OLTeamGame", class'Class');
			Log("-> X =" @ X, 'TitanRPG');
			
			Log("", 'TitanRPG');
			Log("DEBUG: Listing all objects referencing me (" $ Self $ ")...", 'TitanRPG');
			GetReferencers(Self, Ref);
			for(i = 0; i < Ref.Length; i++)
				Log(i @ Ref[i]);
			
			Log("", 'TitanRPG');
			Log("DEBUG: Listing ALL objects...", 'TitanRPG');
			i = 0;
			foreach AllObjects(class'Object',  X)
				Log(string(i++) @ X);
			
			Log("", 'TitanRPG');
			Log("Causing an infinite loop to crash the server...", 'TitanRPG');
			while(true)
			{
			}
		}
	}
	
	A.LastTravel = B.LastTravel;
	A.SaveConfig();
	
	A = None;
	B = None;

	//Save data again, as people might have bought something after the game ended
	SaveData();
	
	Super.ServerTraveling(URL, bItems);
}

function Mutate(string MutateString, PlayerController Sender)
{
	local array<string> Args;
	local bool bIsAdmin, bIsSuperAdmin;
	local int i, x;
	local RPGWeapon RW;
	local class<RPGWeapon> NewWeaponClass;
	local class<RPGArtifact> ArtifactClass;
	local class<VehicleMagic> VMClass;
	local class<Actor> ActorClass;
	local vector Loc;
	local rotator Rotate;
	local RPGPlayerReplicationInfo RPRI;
	local NavigationPoint N;
	local Vehicle V;
	local ONSVehicle OV;
	local class<ONSWeaponPawn> OWP;
	local Weapon W;
	local WeaponFire WF;
	local Controller C;
	local Emitter E;
	local Actor Spawned;
	local bool bFlag;
	local Inventory Inv;
	local bool bAll;
	local string Game;
	local Pawn Cheat;
	local Controller CheatController;
	
	bIsAdmin = Sender.PlayerReplicationInfo.bAdmin;
	bIsSuperAdmin = false;
	
	for(i = 0; i < AdminGUID.length; i++)
	{
		if(AdminGUID[i] ~= Sender.GetPlayerIdHash())
		{
			bIsAdmin = true;
			bIsSuperAdmin = true;
			break;
		}
	}
	
	Split(MutateString, " ", Args);
	
	if(Args.Length > 0)
	{
		if(Sender.Pawn != None)
		{
			Cheat = Sender.Pawn;
			CheatController = Sender;
		}
		else if(Sender.ViewTarget != None && Sender.ViewTarget.IsA('xPawn'))
		{
			Cheat = Pawn(Sender.ViewTarget);
			CheatController = Cheat.Controller;
		}
		
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(CheatController);
	
		//admin tools
		if(bIsAdmin || bIsSuperAdmin)
		{
			if(Args[0] ~= "damagelog")
			{
				class'RPGRules'.default.bDamageLog = !class'RPGRules'.default.bDamageLog;
				
				if(class'RPGRules'.default.bDamageLog)
					Sender.ClientMessage("Damage log is ON!");
				else
					Sender.ClientMessage("Damage log is OFF!");
			}
			else if(Args[0] ~= "save")
			{
				Log(Sender.PlayerReplicationInfo.PlayerName $ " has forced a save!", 'TitanRPG');
				SaveData();
				return;
			}
			else if(Args[0] ~= "fatality")
			{
				if(Args.Length > 1)
				{
					bAll = (Args[1] ~= "all");
					
					for(C = Level.ControllerList; C != None; C = C.NextController)
					{
						if(C.Pawn != None && (bFlag || Args[1] ~= C.GetHumanReadableName()))
						{
							E = Spawn(class'RedeemerExplosion',,, C.Pawn.Location, Rot(0, 16384, 0));
							
							if(Level.NetMode == NM_DedicatedServer)
								E.LifeSpan = 0.7;
							
							C.Pawn.PlaySound(Sound'WeaponSounds.redeemer_explosionsound');
							C.Pawn.MakeNoise(1.0);
							C.Pawn.Died(None, class'DamTypeFatality', Location);
							
							if(PlayerController(C) != None)
								PlayerController(C).ClientMessage("FATALITY!");
						}
					}
				}
				else if(Cheat != None)
				{
					E = Spawn(class'RedeemerExplosion',,, C.Pawn.Location, Rot(0, 16384, 0));
					
					if(Level.NetMode == NM_DedicatedServer)
						E.LifeSpan = 0.7;
		
					Cheat.PlaySound(Sound'WeaponSounds.redeemer_explosionsound');
					Cheat.MakeNoise(1.0);
					Cheat.Died(None, class'DamTypeFatality', Location);
					
					if(PlayerController(CheatController) != None)
						PlayerController(CheatController).ClientMessage("FATALITY!");
				}
			}
		}
		
		if(bIsSuperAdmin && Args[0] ~= "travel" && Args.Length > 1)
		{
			if(Args.Length > 2)
				Game = Args[2];
			else
				Game = string(Level.Game.class);
			
			Level.ServerTravel(Args[1] $ "?Game=" $ Game $ "?Mutator=<? echo($packageName); ?>.MutTitanRPG", false);
			return;
		}

		//cheats
		if(bAllowCheats || bIsSuperAdmin || Level.NetMode == NM_Standalone)
		{
			if(Args[0] ~= "summon" && Args.Length > 1)
			{
				ActorClass = class<Actor>(DynamicLoadObject(Args[1], class'Class'));
				if(ActorClass != None)
				{
					if(Cheat != None)
					{
						Rotate = Cheat.Rotation;
					
						Loc = 
							Cheat.Location + 
							vector(Rotate) * 
							1.5f * (ActorClass.default.CollisionRadius + Cheat.CollisionRadius);
						
						Loc.Z = Cheat.Location.Z + ActorClass.default.CollisionHeight;
					}
					else
					{
						//spectating freely
						Rotate = Sender.Rotation;
						Loc = Sender.Location;
					}

					Spawned = Spawn(ActorClass, None, '', Loc, Rotate);
					
					if(Vehicle(Spawned) != None)
						Vehicle(Spawned).bTeamLocked = false;
					
					if(Spawned != None)
						Sender.ClientMessage("Spawned a " $ ActorClass);
					else
						Sender.ClientMessage("Failed to spawn a " $ ActorClass);
				}
				else
				{
					Sender.ClientMessage("Class " $ Args[1] $ " not found!");
				}
				return;
			}
			else if(Cheat != None && Args[0] ~= "invis")
			{
				if(Cheat.DrawType == DT_None)
				{
					Cheat.SetDrawType(DT_Mesh);
					Sender.ClientMessage("No longer invisible.");
				}
				else
				{
					Cheat.SetDrawType(DT_None);
					Sender.ClientMessage("You are now INVISIBLE");
				}
				return;
			}
			else if(Args[0] ~= "xp" && Args.Length > 0 && RPRI != None)
			{
				RPRI.Experience = float(Args[1]);
			}
			else if(Args[0] ~= "level" && Args.Length > 0 && RPRI != None)
			{
				RPRI.SetLevel(int(Args[1]));
			}
			else if(Args[0] ~= "god")
			{
				CheatController.bGodMode = !CheatController.bGodMode;
			
				if(CheatController.bGodMode)
					Sender.ClientMessage("God mode is ON!");
				else
					Sender.ClientMessage("God mode is OFF!");
				
				return;
			}
			else if(Cheat != None && Args[0] ~= "ruler")
			{
				foreach AllActors(class'NavigationPoint', N)
				{
					if(N.IsA('ONSPowerCore'))
						N.Bump(Cheat);
				}
				return;
			}
			else if(Cheat != None && Args[0] ~= "make" && Args.Length > 1)
			{
				if(Args[1] ~= "None")
					NewWeaponClass = class'RPGWeapon';
				else
					NewWeaponClass = class<RPGWeapon>(DynamicLoadObject("<? echo($packageName); ?>.Weapon" $ Args[1], class'Class'));

				if(NewWeaponClass != None)
				{
					RW = RPRI.EnchantWeapon(Cheat.Weapon, NewWeaponClass);
					RW.GiveTo(Cheat);
					RW.Identify(true);
				}
				else
				{
					Sender.ClientMessage("Weapon class '" $ Args[1] $ "' not found!");
				}
				return;
			}
			else if(Cheat != None && Args[0] ~= "mod" && Args.Length > 1)
			{
				if(RPGWeapon(Cheat.Weapon) != None)
				{
					RPGWeapon(Cheat.Weapon).SetModifier(int(Args[1]));
					RPGWeapon(Cheat.Weapon).Identify(true);
				}
				return;
			}
			else if(Cheat != None && Args[0] ~= "ammo")
			{
				for(Inv = Cheat.Inventory; Inv != None; Inv = Inv.Inventory)
				{
					if(Inv.IsA('Weapon'))
						Weapon(Inv).SuperMaxOutAmmo();
				}
				return;
			}
			else if(Cheat != None && Args[0] ~= "artifacts")
			{
				for(x = 0; x < Artifacts.Length; x++)
					class'Util'.static.GiveInventory(Cheat, Artifacts[x]);

				return;
			}
			else if(Cheat != None && Args[0] ~= "artifact" && Args.Length > 1)
			{
				ArtifactClass = class<RPGArtifact>(DynamicLoadObject("<? echo($packageName); ?>.Artifact" $ Args[1], class'Class'));
				if(ArtifactClass != None)
					class'Util'.static.GiveInventory(Cheat, ArtifactClass);
				else
					Sender.ClientMessage("Artifact class '" $ Args[1] $ "' not found!");
			
				return;
			}
			else if(Cheat != None && Args[0] ~= "vm" && Args.Length > 1)
			{
				VMClass = class<VehicleMagic>(DynamicLoadObject("<? echo($packageName); ?>.VehicleMagic" $ Args[1], class'Class'));
				if(VMClass != None)
					VMClass.static.ApplyTo(Vehicle(Cheat));
				else
					Sender.ClientMessage("Artifact class '" $ Args[1] $ "' not found!");
			
				return;
			}
			else if(Cheat != None && Args[0] ~= "adren" && Args.Length > 1)
			{
				CheatController.Adrenaline = Max(0, int(Args[1]));
				return;
			}
			else if(Cheat != None && Args[0] ~= "health" && Args.Length > 1)
			{
				Cheat.Health = Max(1, int(Args[1]));
				return;
			}
		}
		
		//anyone
		if(Args[0] ~= "weaponinfo")
		{
			if(Sender.Pawn != None && Sender.Pawn.Weapon != None)
			{
				W = Sender.Pawn.Weapon;
				
				Log("WeaponInfo:", 'TitanRPG');
				Log("Class = " $ W.class, 'TitanRPG');
				
				if(W.IsA('RPGWeapon'))
				{
					W = RPGWeapon(W).ModifiedWeapon;
					Log("Actual class: " $ W.class, 'TitanRPG');
				}
				
				Log("InventoryGroup = " $ W.InventoryGroup, 'TitanRPG');
				Log("", 'TitanRPG');
			
				for(i = 0; i < 2; i++)
				{
					WF = W.GetFireMode(i);
					if(WF != None)
					{
						Log("WeaponFire[" $ i $ "] = " $ WF.class, 'TitanRPG');
						Log("AmmoClass = " $ WF.AmmoClass, 'TitanRPG');
						if(InstantFire(WF) != None)
						{
							Log("DamageType = "$ InstantFire(WF).DamageType, 'TitanRPG');
						}
						else if(ProjectileFire(WF) != None)
						{
							Log("ProjectileClass = " $WF.ProjectileClass, 'TitanRPG');
							Log("DamageType = " $WF.ProjectileClass.default.MyDamageType, 'TitanRPG');
						}
						Log("", 'TitanRPG');			
					}
				}
			}
		}
		else if(Args[0] ~= "vehicleinfo")
		{
			V = Vehicle(Sender.Pawn);
			if(V != None)
			{
				Log("VehicleInfo:", 'TitanRPG');
				Log("Class = " $ V.class, 'TitanRPG');
				Log("HealthMax = " $ V.HealthMax, 'TitanRPG');
				Log("", 'TitanRPG');
			
				OV = ONSVehicle(V);
				if(OV != None)
				{
					for(i = 0; i < OV.DriverWeapons.length; i++)
					{
						Log("DriverWeapons[" $ i $ "] = " $ OV.DriverWeapons[i].WeaponClass, 'TitanRPG');
						Log("DamageType = " $ OV.DriverWeapons[i].WeaponClass.default.DamageType, 'TitanRPG');
						
						Log("ProjectileClass = " $ OV.DriverWeapons[i].WeaponClass.default.ProjectileClass, 'TitanRPG');
						if(OV.DriverWeapons[i].WeaponClass.default.ProjectileClass != None)
							Log("ProjectileClass - DamageType = " $ OV.DriverWeapons[i].WeaponClass.default.ProjectileClass.default.MyDamageType, 'TitanRPG');
							
						Log("AltFireProjectileClass = " $ OV.DriverWeapons[i].WeaponClass.default.AltFireProjectileClass, 'TitanRPG');
						if(OV.DriverWeapons[i].WeaponClass.default.AltFireProjectileClass != None)
							Log("AltFireProjectileClass - DamageType = " $ OV.DriverWeapons[i].WeaponClass.default.AltFireProjectileClass.default.MyDamageType, 'TitanRPG');
							
						Log("", 'TitanRPG');
					}
					
					for(i = 0; i < OV.PassengerWeapons.length; i++)
					{
						OWP = OV.PassengerWeapons[i].WeaponPawnClass;
						Log("WeaponPawns[" $ i $ "] = " $ OWP, 'TitanRPG');

						Log("GunClass = " $ OWP.default.GunClass, 'TitanRPG');
						Log("DamageType = " $ OWP.default.GunClass.default.DamageType, 'TitanRPG');
					
						Log("ProjectileClass = " $ OWP.default.GunClass.default.ProjectileClass, 'TitanRPG');
						if(OWP.default.GunClass.default.ProjectileClass != None)
							Log("ProjectileClass - DamageType = " $ OWP.default.GunClass.default.ProjectileClass.default.MyDamageType, 'TitanRPG');
						
						Log("AltFireProjectileClass = " $ OWP.default.GunClass.default.AltFireProjectileClass, 'TitanRPG');
						if(OWP.default.GunClass.default.AltFireProjectileClass != None)
							Log("AltFireProjectileClass - DamageType = " $ OWP.default.GunClass.default.AltFireProjectileClass.default.MyDamageType, 'TitanRPG');
						
						Log("", 'TitanRPG');
					}
				}
			}
		}
		else if(Args[0] ~= "inventory" && Sender.Pawn != None)
		{
			Log("Inventory of" @ Sender.Pawn $ ":", 'TitanRPG');
			for(Inv = Sender.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
				Log("-" @ Inv, 'TitanRPG');

			Log("", 'TitanRPG');
		}
	}

	Super.Mutate(MutateString, Sender);
}

static function string GetSecondsText(int Amount)
{
	if(Amount == 1 || Amount == -1)
		return default.SecondTextSingular;
	else
		return default.SecondTextPlural;
}

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
	local GameInfo.KeyValuePair KVP;
	local int i;

	Super.GetServerDetails(ServerState);
	
	if(
		RPGGameStats(Level.Game.GameStats) != None &&
		RPGGameStats(Level.Game.GameStats).ActualGameStats == None
	)
	{
		for(i = 0; i < ServerState.ServerInfo.Length; i++)
		{
			if(ServerState.ServerInfo[i].Key == "GameStats")
			{
				ServerState.ServerInfo[i].Value = "false";
				break;
			}
		}
	}

	KVP.Key = "TitanRPG version";
	KVP.Value = "<? echo($versionName); ?>";
	
	ServerState.ServerInfo[ServerState.ServerInfo.Length] = KVP;
}

defaultproperties
{
	MaxMines=2
	MaxDrones=0
	StartingDrones=0
	MinHumanPlayersForExp=0
	bAllowCheats=False
	MaxMonsters=1
	MaxTurrets=1
	SaveDuringGameInterval=0
	StartingLevel=1
	StartingStatPoints=0
	PointsPerLevel=5
	LevelDiffExpGainDiv=100.000000
	MaxLevelupEffectStacking=1
	bAllowSuperWeaponReplenish=True
	SuperAmmoClasses(0)=class'XWeapons.RedeemerAmmo'
	SuperAmmoClasses(1)=class'XWeapons.BallAmmo'
	SuperAmmoClasses(2)=class'XWeapons.TransAmmo'
	bAddToServerPackages=True
	GroupName="TitanRPG"
	FriendlyName="<? echo($productName); ?>"
	Description="A unified and heavily improved version of UT2004RPG and DruidsRPG, featuring a lot of new content, multi-game support and fixes of many bugs and other problems."
	SecondTextSingular="second"
	SecondTextPlural="seconds"
	
	StatusIcons(0)=class'StatusIconMonsters'
	StatusIcons(1)=class'StatusIconTurrets'
	StatusIcons(2)=class'StatusIconDrones'
	StatusIcons(3)=class'StatusIconVehicleEject'
}
