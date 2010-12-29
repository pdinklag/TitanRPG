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

//Stuff
var config bool bAllowSuperWeaponReplenish; //allow RPGWeapon::FillToInitialAmmo() on superweapons
var config array<class<Ammunition> > SuperAmmoClasses;

var config int MaxDrones, StartingDrones;
var config int MaxMonsters; //minimum MaxMonsters per player...
var config int MaxTurrets; //minimum MaxTurrets per player...

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
		else if(InventoryClassName ~= "Onslaught.ONSMineLayer")
			return "OLTeamGames.OLTeamsONSMineLayer";
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
	
	//Monster fake weapon (for NetDamage to be called)
	if(Other.IsA('Monster'))
	{
		Spawn(class'FakeMonsterWeapon', Other).GiveTo(Pawn(Other));
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

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	local int x, Chance;

	if(FRand() < GameSettings.WeaponModifierChance)
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
		Log("DEBUG: Last travel was" @ TravelTimeDiff @ "seconds ago.", 'TitanRPG');
		
		if(TravelTimeDiff < 5)
		{
			Log("=> LOOP DETECTED", 'TitanRPG');
			
			Log("");
			Log("DEBUG: Testing file output to 'loop.log'...", 'TitanRPG');
			FLog = Spawn(class'FileLog');
			FLog.OpenLog("loop.log",, true);
			FLog.Logf("Testing file output - if this file is not in UserLogs, something's seriously wrong...");
			FLog.CloseLog();
			FLog.Destroy();
			Flog = None;
			
			Log("");
			Log("DEBUG: Trying to obtain an object from an unused package (class'OLTeamGames.OLTeamGame')...", 'TitanRPG');
			X = DynamicLoadObject("OLTeamGames.OLTeamGame", class'Class');
			Log("-> X =" @ X, 'TitanRPG');
			
			Log("");
			Log("DEBUG: Listing all objects referencing me (" $ Self $ ")...", 'TitanRPG');
			GetReferencers(Self, Ref);
			for(i = 0; i < Ref.Length; i++)
				Log(i @ Ref[i]);
			
			Log("");
			Log("DEBUG: Listing ALL objects...", 'TitanRPG');
			i = 0;
			foreach AllObjects(class'Object',  X)
				Log(string(i++) @ X);
			
			Log("");
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
	local bool bIsAdmin, bIsSuperAdmin;
	local string desc;
	local int i, x;
	local Weapon OldWeapon, Copy;
	local class<RPGWeapon> NewWeaponClass;
	local class<RPGArtifact> ArtifactClass;
	local class<VehicleMagic> VMClass;
	local class<Weapon> OldWeaponClass;
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
	local FileLog FLog;
	
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
	
	//admin tools
	if(bIsAdmin || bIsSuperAdmin)
	{
		if(MutateString ~= "damagelog")
		{
			class'RPGRules'.default.bDamageLog = !class'RPGRules'.default.bDamageLog;
			
			if(class'RPGRules'.default.bDamageLog)
				Sender.ClientMessage("Damage log is ON!");
			else
				Sender.ClientMessage("Damage log is OFF!");
		}
		else if(MutateString ~= "countflogs")
		{
			Sender.ClientMessage("Counting FileLog actors...");
			
			x = 0;
			foreach AllActors(class'FileLog', FLog)
			{
				Sender.ClientMessage("-" @ FLog);
				x++;
			}
			
			Sender.ClientMessage(x @ "FileLog actors detected");
		}
		else if(MutateString ~= "save")
		{
			//useful if the server has to be shut down
			Log(Sender.PlayerReplicationInfo.PlayerName $ " has forced a save!", 'TitanRPG');
			SaveData();
			return;
		}
		else if(Left(MutateString, Len("fatality")) ~= "fatality")
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("fatality")));
			bFlag = (desc ~= "all");
			
			for(C = Level.ControllerList; C != None; C = C.NextController)
			{
				if(C.Pawn != None && (bFlag || desc ~= C.GetHumanReadableName()))
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
	}
	
	if(bIsSuperAdmin && Left(MutateString, Len("travel")) ~= "travel")
	{
		desc = class'Util'.static.Trim(Mid(MutateString, Len("travel")));
		Level.ServerTravel(desc $ "?Game=XGame.xVehicleCTFGame?Mutator=TitanRPG.MutTitanRPG", false);
		return;
	}

	//cheats
	if(bAllowCheats || bIsSuperAdmin || Level.NetMode == NM_Standalone)
	{
		if(Left(MutateString, Len("summon")) ~= "summon")
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("summon")));
			
			ActorClass = class<Actor>(DynamicLoadObject(desc, class'Class'));
			if(ActorClass != None)
			{
				if(Sender.Pawn != None)
				{
					Rotate = Sender.Pawn.Rotation;
				
					Loc = 
						Sender.Pawn.Location + 
						vector(Rotate) * 
						1.5f * (ActorClass.default.CollisionRadius + Sender.Pawn.CollisionRadius);
					
					Loc.Z = Sender.Pawn.Location.Z + ActorClass.default.CollisionHeight;
				}
				else
				{
					//spectating
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
				Sender.ClientMessage("Class " $ desc $ " not found!");
			}
		}
		else if(Sender.Pawn != None && MutateString ~= "invis")
		{
			if(Sender.Pawn.DrawType == DT_None)
			{
				Sender.Pawn.SetDrawType(DT_Mesh);
				Sender.ClientMessage("You are no longer invisible");
			}
			else
			{
				Sender.Pawn.SetDrawType(DT_None);
				Sender.ClientMessage("You are now INVISIBLE");
			}
		}
		else if(MutateString ~= "god")
		{
			Sender.bGodMode = !Sender.bGodMode;
		
			if(Sender.bGodMode)
				Sender.ClientMessage("God mode is ON!");
			else
				Sender.ClientMessage("God mode is OFF!");
		}
		else if(Sender.Pawn != None && MutateString ~= "ruler")
		{
			foreach AllActors(class'NavigationPoint', N)
			{
				if(N.IsA('ONSPowerCore'))
					N.Bump(Sender.Pawn);
			}
		}
		else if(Sender.Pawn != None && Left(MutateString, Len("make")) ~= "make")
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("make")));

			if(desc ~= "None")
				NewWeaponClass = class'RPGWeapon';
			else
				NewWeaponClass = class<RPGWeapon>(DynamicLoadObject("<? echo($packageName); ?>.Weapon" $ desc, class'Class'));

			if(NewWeaponClass != None)
			{
				OldWeapon = Sender.Pawn.Weapon;
				if(OldWeapon == None)
					return;

				if(OldWeapon.isA('RPGWeapon'))
					OldWeaponClass = RPGWeapon(OldWeapon).ModifiedWeapon.class;
				else
					OldWeaponClass = OldWeapon.class;

				Copy = Spawn(NewWeaponClass, Instigator,,, rot(0,0,0));
				if(Copy == None)
					return;

				RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Sender);
				if (RPRI != None)
				{
					for (x = 0; x < RPRI.OldRPGWeapons.length; x++)
					{
						if(oldWeapon == RPRI.OldRPGWeapons[x].Weapon)
						{
							RPRI.OldRPGWeapons.Remove(x, 1);
							break;
						}
					}
				}

				if(RPGWeapon(Copy) == None)
					return;

				//try to generate a positive weapon.
				for(x = 0; x < 50; x++)
				{
					RPGWeapon(Copy).Generate(None);
					if(RPGWeapon(Copy).Modifier > -1)
						break;
				}

				RPGWeapon(Copy).SetModifiedWeapon(Spawn(OldWeaponClass, Sender.Pawn,,, rot(0,0,0)), true);

				OldWeapon.DetachFromPawn(Sender.Pawn);
				if(OldWeapon.isA('RPGWeapon'))
				{
					RPGWeapon(OldWeapon).ModifiedWeapon.Destroy();
					RPGWeapon(OldWeapon).ModifiedWeapon = None;
				}
				OldWeapon.Destroy();
				Copy.GiveTo(Sender.Pawn);
				RPGWeapon(Copy).Identify(true);
			}
			else
			{
				Log("CHEAT: Weapon class " $ desc $ " not found!", 'TitanRPG');
			}
			return;
		}
		else if(Sender.Pawn != None && Left(MutateString, Len("mod")) ~= "mod")
		{
			x = int(class'Util'.static.Trim(Mid(MutateString, Len("make"))));
			if(RPGWeapon(Sender.Pawn.Weapon) != None)
			{
				RPGWeapon(Sender.Pawn.Weapon).SetModifier(x);
				RPGWeapon(Sender.Pawn.Weapon).Identify(true);
			}

			return;
		}
		else if(Sender.Pawn != None && MutateString ~= "artifacts")
		{
			for(x = 0; x < Artifacts.Length; x++)
				class'Util'.static.GiveInventory(Sender.Pawn, Artifacts[x]);

			return;
		}
		else if(Sender.Pawn != None && MutateString ~= "ammo")
		{
			if(Sender.Pawn.Weapon != None)
				Sender.Pawn.Weapon.SuperMaxOutAmmo();

			return;
		}
		else if(Sender.Pawn != None && Left(MutateString, Len("artifact")) ~= "artifact")
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("artifact")));
			
			ArtifactClass = class<RPGArtifact>(DynamicLoadObject("<? echo($packageName); ?>.Artifact" $ desc, class'Class'));
			if(ArtifactClass != None)
				class'Util'.static.GiveInventory(Sender.Pawn, ArtifactClass);
			else
				Log("CHEAT: Artifact class " $ desc $ " not found!", 'TitanRPG');
		
			return;
		}
		else if(Sender.Pawn != None && Left(MutateString, Len("vm")) ~= "vm" && Vehicle(Sender.Pawn) != None)
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("vm")));
			
			VMClass = class<VehicleMagic>(DynamicLoadObject("<? echo($packageName); ?>.VehicleMagic" $ desc, class'Class'));
			if(VMClass != None)
				VMClass.static.ApplyTo(Vehicle(Sender.Pawn));
			else
				Log("CHEAT: Vehicle magic class " $ desc $ " not found!", 'TitanRPG');
		
			return;
		}
		else if(Sender.Pawn != None && Left(MutateString, Len("adren")) ~= "adren")
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("adren")));
			Sender.Adrenaline = Max(0, int(desc));
			return;
		}
		else if(Sender.Pawn != None && Left(MutateString, Len("health")) ~= "health")
		{
			desc = class'Util'.static.Trim(Mid(MutateString, Len("health")));
			Sender.Pawn.Health = Max(1, int(desc));
			return;
		}
	}
	
	//anyone
	if(MutateString ~= "weaponinfo")
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
	else if(MutateString ~= "vehicleinfo")
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
	else if(MutateString ~= "inventory" && Sender.Pawn != None)
	{
		Log("Inventory of" @ Sender.Pawn $ ":", 'TitanRPG');
		for(Inv = Sender.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
			Log("-" @ Inv, 'TitanRPG');

		Log("", 'TitanRPG');
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
}
