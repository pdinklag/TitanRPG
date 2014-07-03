class MutTitanRPG extends Mutator
	config(TitanRPG);

//Import resources
#exec OBJ LOAD FILE=Resources/TitanRPG_rc.u PACKAGE=TitanRPG

//Saving
var config array<string> IgnoreNameTag;
var config int SaveDuringGameInterval;
var float NextSaveTime;

//General
var string PackageName;
var RPGRules Rules;

var config string CustomVersion;
var config bool bAllowCheats;
var config int StartingLevel, StartingStatPoints;
var config int PointsPerLevel;
var config int MinHumanPlayersForExp;
var config array<int> Levels;
var config bool bLevelCap; //can't reach more levels than defined in the array above
var config int MaxLevelReqExpPerLevel; //if bLevelCap is False, each level beyond the limit will require this much more experience in order to advance
var config float LevelDiffExpGainDiv; //divisor to extra experience from defeating someone of higher level (a value of 1 results in level difference squared EXP)
var config int MaxLevelupEffectStacking;
var config array<class<RPGAbility> > Abilities;
var config array<class<RPGAbility> > Stats;
var config array<class<RPGArtifact> > Artifacts; //artifacts that are displayed in the HUD

var localized string SecondTextSingular, SecondTextPlural;

var config array<class<RPGArtifact> > DefaultArtifacts; //artifacts that players spawn with
var config array<class<Combo> > Combos; //additional combos to enable for players

var config array<class<Weapon> > DisallowModifiersFor; //these weapons can not be modified

//Invasion
var config bool bAutoAdjustInvasionLevel; //auto adjust invasion monsters' level based on lowest level player
var config float InvasionAutoAdjustFactor; //affects how dramatically monsters increase in level for each level of the lowest level player
var float InvasionDamageAdjustment; //calculated from lowest player level and a lot of Mysterial's mojo

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
	var class<RPGWeaponModifier> ModifierClass;
	var int Chance;
};

var config array<WeaponModifier> WeaponModifiers;
var int TotalModifierChance;

//Stuff
var config array<class<Ammunition> > SuperAmmoClasses;

var config int MaxMonsters; //minimum MaxMonsters per player...
var config bool bMonstersDie; //if True, all monsters summoned by a player die when the player dies

var config int MaxTurrets; //minimum MaxTurrets per player...
var config bool bTurretsDie; //if True, all turrets built by a player die when the player dies

var config int MaxTotems; //minimum MaxTotems per player...
var config bool bTotemsDie; //if True, all totems built by a player die when the player dies

var config int MaxMines; //minimum MaxMines per player...

//admin commands
var config array<String> AdminGUID;

//INIT stuff
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
    
    //Config ability
    if(Left(Alias, 1) == "@") {
        return class'RPGConfigAbility'.static.Resolve(Mid(Alias, 1));
    }
    
    //Normal abilities
	Alias = Repl(Alias, "#", "Ability_");
	for(i = 0; i < Abilities.Length; i++)
	{
		if(string(Abilities[i].Name) ~= Alias)
			return Abilities[i];
	}
	
	//Fallback, for seamless transitions from 1.5 or earlier
	Loaded = class<RPGAbility>(DynamicLoadObject(PackageName $ ".Ability" $ Alias, class'Class'));

	if(Loaded == None)
		Log("WARNING: Could not resolve ability alias:" @ Alias, 'TitanRPG');

	return Loaded;
}

static final function string GetAbilityAlias(class<RPGAbility> AbilityClass)
{
    local class<RPGGeneratedAbility> GenClass;

    GenClass = class<RPGGeneratedAbility>(AbilityClass);
    if(GenClass != None) {
        return "@" $ GenClass.default.Module.ModuleName;
    } else {
        return Repl(string(AbilityClass.Name), "Ability_", "#");
    }
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

event PreBeginPlay() {
    local array<string> ConfigAbilityNames;
    local RPGConfigAbility Module;
    local class<RPGAbility> AbilityClass;
	local int i, x;
	
    x = InStr(string(default.class), ".");
    default.PackageName = Left(string(default.class), x);
    PackageName = default.PackageName;

	if(!Level.Game.IsA('Invasion'))
		bAutoAdjustInvasionLevel = false; //don't waste any time doing Invasion stuff if we're not in Invasion

	//OLTeamGames support
	bOLTeamGames = Level.Game.IsA('OLTeamGame');

	//Register stats as abilities internally, makes replication easier
	for(i = 0; i < Stats.Length; i++)
		Abilities[Abilities.Length] = Stats[i];

    //Generate ability modules
    class'RPGConfigAbility'.static.ResetAll();
    
    ConfigAbilityNames = class'RPGConfigAbility'.static.GetPerObjectNames("TitanRPG", string(class'RPGConfigAbility'.name));
    for(i = 0; i < ConfigAbilityNames.Length; i++) {
        Module = new(None, ConfigAbilityNames[i]) class'RPGConfigAbility';
        Module.ModuleName = ConfigAbilityNames[i];
        AbilityClass = Module.InitAbility();
        if(AbilityClass != None) {
            Abilities.Insert(0, 1);
            Abilities[0] = AbilityClass;
        } else {
            Warn("Failed to initialize ability for module" @ Module.ModuleName);
            break;
        }
    }

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
		Level.Game.PlayerControllerClassName = PackageName $ ".TitanPlayerController";

	//Find specific settings for this gametype
	GameSettings = new(None, GetGameSettingsName(Level.Game)) class'RPGGameSettings';
	
	DeathMatch(Level.Game).bAllowTrans = GameSettings.bAllowTrans;
	DeathMatch(Level.Game).bAllowVehicles = GameSettings.bAllowVehicles;
}

event PostBeginPlay()
{
    local Mutator Mut;
	local GameObjective Objective;
	local HealableDamageGameRules HealRules;
	local RPGReplicationInfo RRI;
	local int x;
    
    //Disable ONS mutator as it disables adrenaline pickups
    for(Mut = Level.Game.BaseMutator; Mut != None; Mut = Mut.NextMutator) {
        if(Mut.IsA('ONSDefaultMut')) {
            Mut.Destroy();
            break;
        }
    }
	
	//RPG Rules
	Rules = Spawn(class'RPGRules');
	Rules.RPGMut = self;
	Rules.PointsPerLevel = PointsPerLevel;
	Rules.LevelDiffExpGainDiv = LevelDiffExpGainDiv;
	
	Rules.NextGameRules = Level.Game.GameRulesModifiers;
	Level.Game.GameRulesModifiers = Rules;
	
	//Game objective observers
	foreach AllActors(class'GameObjective', Objective) {
        if(Objective.IsA('CTFBase')) { //CTF flag base
            Spawn(class'RPGFlagObserver', Objective);
        } else if(Objective.IsA('xBombSpawn')) { //BR ball spawn
            Spawn(class'RPGBallObserver', Objective);
        } else if(Objective.IsA('ONSPowerCore')) { //ONS power nodes and power cores
            Spawn(class'RPGPowerCoreObserver', Objective);
        }

        //TODO: ONS, Assault, Domination
	}
	
	//Healable damage rules
	HealRules = Spawn(class'HealableDamageGameRules');
	HealRules.NextGameRules = Rules.NextGameRules;
	Rules.NextGameRules = HealRules;

	//Modifiers
	for(x = 0; x < WeaponModifiers.Length; x++)
		TotalModifierChance += WeaponModifiers[x].Chance;

	//Pickup spawner
    if(GameSettings.bEnablePickupSpawner) {
        Spawn(class'RPGPickupSpawner', Self);
    }
	
	//Save
	if(SaveDuringGameInterval > 0)
		NextSaveTime = Level.TimeSeconds + float(SaveDuringGameInterval);

	//Timer
	SetTimer(Level.TimeDilation, true);

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
		return PackageName $ ".RPGRocketLauncher";
	else if(InventoryClassName ~= "XWeapons.ShieldGun" || InventoryClassName ~= "OLTeamGames.OLTeamsShieldGun")
		return PackageName $ ".RPGShieldGun";
	else if(InventoryClassName ~= "XWeapons.LinkGun" || InventoryClassName ~= "OLTeamGames.OLTeamsLinkGun")
		return PackageName $ ".RPGLinkGun";
	else if(InventoryClassName ~= "Onslaught.ONSMineLayer" || InventoryClassName ~= "OLTeamGames.OLTeamsONSMineLayer")
		return PackageName $ ".RPGMineLayer";
	else if(InventoryClassName ~= "XWeapons.BallLauncher")
		return PackageName $ ".RPGBallLauncher";
	else if(InventoryClassName ~= "UTClassic.ClassicSniperRifle")
		return PackageName $ ".RPGClassicSniperRifle";

	return InventoryClassName;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local int i;
	local WeaponLocker Locker;
    local RPGWeaponModifier WM;
    local RPGWeaponPickupModifier WPM;
    local RPGPlayerReplicationInfo RPRI;
	local Weapon W;
    local WeaponPickup WP;
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
	
	if(Other.IsA('UnrealPawn'))
	{
		if(Other.IsA('Monster'))
		{
			Pawn(Other).HealthMax = Pawn(Other).Health; //fix, e.g. to allow healing properly
		}
	
		//Required Equipment
		for(i = 0; i < 16; i++)
			UnrealPawn(Other).RequiredEquipment[i] = GetInventoryClassOverride(UnrealPawn(Other).RequiredEquipment[i]);
		
		return true;
	}
	
	//Ball Launcher
	if(Other.IsA('xBombFlag'))
	{
		xBombFlag(Other).BombLauncherClassName = PackageName $ ".RPGBallLauncher";
		return true;
	}
	
    //Replace locker weapons
    if(Other.IsA('WeaponLocker')) {
        Locker = WeaponLocker(Other);
    
        for(i = 0; i < Locker.Weapons.length; i++) {
            if(Locker.Weapons[i].WeaponClass != None) {
                ClassName = String(Locker.Weapons[i].WeaponClass);
                NewClassName = GetInventoryClassOverride(ClassName);

                if(!(NewClassName ~= ClassName))
                    Locker.Weapons[i].WeaponClass = class<Weapon>(DynamicLoadObject(NewClassName, class'Class'));
            }
        }
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
    
    //Modified weapon pickup
    if(Other.IsA('WeaponPickup')) {
        WP = WeaponPickup(Other);
    
        //Thrown weapon
        if(WP.Instigator != None && WP.Instigator.Weapon != None) {
            //Add to thrown weapons
            RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(WP.Instigator.Controller);
            if(RPRI != None) {
                RPRI.AddThrownWeapon(WP.Instigator.Weapon.class);
            }
        
            //Apply modifier
            WM = class'RPGWeaponModifier'.static.GetFor(WP.Instigator.Weapon);
            if(WM != None) {
                WPM = class'RPGWeaponPickupModifier'.static.Modify(WP, WM);
            }
        }
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
				if (W.FireModeClass[i] == class'ONSAVRiLFire')
					W.FireModeClass[i] = class'RPGONSAVRiLFire';
				else if(W.FireModeClass[i] == class'TransFire' || string(W.FireModeClass[i]) ~= "OLTeamGames.OLTeamsTransFire")
					W.FireModeClass[i] = class'RPGTransFire';
                else if(W.FireModeClass[i] == class'FM_Sentinel_Fire')
                    W.FireModeClass[i] = class'RPGSentinelFire';
			}
		}
        
        //Assault rifle pickup fix
        if(W.PickupClass == class'AssaultRiflePickup') {
            W.PickupClass = class'RPGAssaultRiflePickup';
        }

		return true;
	}
    
    //Observe combos
    if(Other.IsA('Combo')) {
        Spawn(class'RPGComboObserver', Other);
    }
	
	//Force adrenaline on
	if(Other.IsA('Controller')) {
		Controller(Other).bAdrenalineEnabled = true;
        
        if(Level.Game.IsA('ONSOnslaughtGame') && MessagingSpectator(Other) == None) {
            //Mimic ONSDefaultMut, which has been removed
            Controller(Other).PlayerReplicationInfoClass = class'ONSPlayerReplicationInfo';
        }
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
	//If stats are disabled, create the game stats override here
	if(!bGameStarted && !Level.Game.bWaitingToStartMatch)
	{
		//needed for anything?
		bGameStarted = true;
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
        
        //Announcements
        RPRI.AnnounceBotRoles();
        RPRI.AnnounceMyRole();
	}
	return RPRI;
}

function ModifyPlayer(Pawn Other)
{
	local RPGPlayerReplicationInfo RPRI;
	local int x;
	local Inventory Inv;
	local class<RPGWeaponModifier> ModifierClass;
	
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

    //Modify starting weapons
    if(GameSettings.WeaponModifierChance > 0 && GameSettings.bMagicalStartingWeapons) {
        for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory) {
            if(Inv.IsA('Weapon')) {
                ModifierClass = GetRandomWeaponModifier(Weapon(Inv).class, Other);
                if(ModifierClass != None) {
                    ModifierClass.static.Modify(Weapon(Inv), -100, GameSettings.bNoUnidentified);
                }
            }
        }
        
        Other.Controller.ClientSwitchToBestWeapon();
    }

	//set pawn's properties
	RPRI.ModifyPlayer(Other);
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
	local TransLauncher TL;
	local Inventory Inv;
	local int i;
	local array<RPGArtifact> MyArtifacts;
	local RPGPlayerReplicationInfo RPRI;
	
	//if this player has a translocator and the beacon isn't broken, return it to the player!
	TL = TransLauncher(P.FindInventoryType(class'TransLauncher'));
	if(TL != None && TL.TransBeacon != None && !TL.TransBeacon.Disrupted())
	{
		TL.TransBeacon.Destroy();
		TL.TransBeacon = None;
	}
	
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

	Super.DriverEnteredVehicle(V, P);
}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
	local Inventory Inv;
	local array<RPGArtifact> MyArtifacts;
	local int i;
	local RPGPlayerReplicationInfo RPRI;
	
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

function int GetRequiredXpForLevel(int Level) {
    //Reminder: Levels[i] is the experience required to reach level i, not i-1 !
    if(Level < Levels.Length) {
        return Levels[Level];
    } else if(bLevelCap) {
        return 0;
    } else {
        return Levels[Levels.Length - 1] + MaxLevelReqExpPerLevel * (Level - Levels.Length + 1);
    }
}

//Check the player data at the given index for errors (too many/not enough stat points, invalid abilities)
//Converts the data by giving or taking the appropriate number of stat points and refunding points for abilities bought that are no longer allowed
//This allows the server owner to change points per level settings and/or the abilities allowed and have it affect already created players properly
//This method also makes sure the "experience needed" is synchronized with the configuration.
//If the "experience needed" has changed in the config, the player's experience will be adjusted so it fits.
function ValidateData(RPGPlayerReplicationInfo RPRI) {
	local int ShouldBe, TotalPoints, x, y;
    local float Pct, XP;
    local bool bSave;

    //Validate stats and abilities
	for(x = 0; x < RPRI.Abilities.length; x++)
	{
		if(class'Util'.static.InArray(RPRI.Abilities[x].class, Abilities) >= 0)
		{
            if(RPRI.Abilities[x].AbilityLevel > RPRI.Abilities[x].MaxLevel) {
                Log(RPRI.RPGName @ "has level" @ RPRI.Abilities[x].AbilityLevel @ "of" @ RPRI.Abilities[x].AbilityName $
                    ", but max is" @ RPRI.Abilities[x].MaxLevel @ "- fixed.", 'TitanRPG');
                
                RPRI.Abilities[x].AbilityLevel = RPRI.Abilities[x].MaxLevel;
                bSave = true;
            }
        
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
		Warn(RPRI.RPGName @ "had" @ TotalPoints @ "total stat points at Level" @ RPRI.RPGLevel $
            ", should be" @ ShouldBe $ ", PointsAvailable changed by" @ string(ShouldBe - TotalPoints) @
            "to compensate.");
		/*Log("Here's a breakdown:", 'TitanRPG');
		Log(RPRI.PointsAvailable $ " (Points available)", 'TitanRPG');
		for (x = 0; x < RPRI.Abilities.Length; x++)
		{
			for(y = 0; y < RPRI.Abilities[x].AbilityLevel; y++)
				Log("+ " $ RPRI.Abilities[x].CostForNextLevel(y) $ " (" $ RPRI.Abilities[x].default.AbilityName $ " " $ (y + 1) $ ")", 'TitanRPG');
		}
		Log("= " $ TotalPoints, 'TitanRPG');
		Log("", 'TitanRPG');*/
		
		RPRI.PointsAvailable += ShouldBe - TotalPoints;
        
        if(RPRI.AIBuild != None) {
            //Update AI build
            RPRI.AIBuild.Build(RPRI);
        }
        
        bSave = true;
	}
    
    //Validate XP scale
    ShouldBe = GetRequiredXpForLevel(RPRI.RPGLevel);
    if(RPRI.NeededExp != ShouldBe) {
        if(RPRI.NeededExp > 0 && ShouldBe > 0) {
            Pct = RPRI.Experience / float(RPRI.NeededExp);
            XP = Pct * float(ShouldBe);
        } else {
            XP = RPRI.Experience;
        }
        
        Warn(RPRI.RPGName @ "needs" @ RPRI.NeededExp @ "XP to get to level" @ string(RPRI.RPGLevel + 1) $
            ", should be" @ ShouldBe $ ", XP adjusted from" @ RPRI.Experience @ "to" @ XP @
            "to compensate.");
        
        RPRI.NeededExp = ShouldBe;
        RPRI.Experience = XP;
        
        if(RPRI.PlayerLevel != None) {
            RPRI.PlayerLevel.Experience = XP;
            RPRI.PlayerLevel.ExpNeeded = ShouldBe;
        }
        
        bSave = true;
    }
    
    if(bSave) {
        RPRI.SaveData();
    }
}

function bool CheckPDP(Pawn Other, class<Weapon> WeaponType) {
    local RPGPlayerReplicationInfo RPRI;

    //PDP protection
    RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Other.Controller);
    if(RPRI != None && RPRI.HasThrownWeapon(WeaponType)) {
        return false;
    } else {
        return true;
    }
}

function class<RPGWeaponModifier> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other, optional bool bForceModifier)
{
	local int x, Chance;

    //Generate
    //TODO: fair algorithm (this one favors those first in the list)
    if(WeaponModifiers.Length > 0) {
        if(bForceModifier || FRand() < GameSettings.WeaponModifierChance)
        {
            Chance = Rand(TotalModifierChance);
            for (x = 0; x < WeaponModifiers.Length; x++)
            {
                Chance -= WeaponModifiers[x].Chance;
                if (Chance < 0 && WeaponModifiers[x].ModifierClass.static.AllowedFor(WeaponType, Other))
                    return WeaponModifiers[x].ModifierClass;
            }
        }
    }
	return None;
}

function NotifyLogout(Controller Exiting)
{
	local RPGPlayerReplicationInfo RPRI;
	
	Super.NotifyLogout(Exiting);
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Exiting);
	if(RPRI != None)
	{
		RPRI.SaveData();
		RPRI.Destroy();
	}
}

function Timer()
{
	local int LowestLevel;
	local RPGPlayerReplicationInfo RPRI;
	local Controller C;

	if(SaveDuringGameInterval > 0 && Level.TimeSeconds >= NextSaveTime)
	{
		SaveData();
		NextSaveTime = Level.TimeSeconds + float(SaveDuringGameInterval);
	}
	
	//find level of lowest level player
	if(Level.Game.IsA('Invasion') && bAutoAdjustInvasionLevel)
	{
		LowestLevel = 0;
		for(C = Level.ControllerList; C != None; C = C.NextController)
		{
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
			if(RPRI != None && (LowestLevel == 0 || RPRI.RPGLevel < LowestLevel))
				LowestLevel = RPRI.RPGLevel;
		}
		
		if(LowestLevel > 0)
		{
			InvasionDamageAdjustment = 
				0.0025f * float(PointsPerLevel) * (
				2 * (Invasion(Level.Game).WaveNum + 1) +
				float(LowestLevel) * InvasionAutoAdjustFactor);
		}
	}
	else
	{
		InvasionDamageAdjustment = 0;
	}
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

	//Reset score
	RPRI.PRI.Score = 0.f;
	
	//"reconnect"
	RPRI.Destroy();
}

function string NewRecommendCombo(string ComboName, AIController C) {
    local RPGPlayerReplicationInfo RPRI;
    
    RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
    if(RPRI != None && RPRI.HasAbility(class'Ability_ComboTeamBooster') > 0) {
        //this bot is a medic, tell him to do the team booster combo!
        return string(class'ComboTeamBooster');
    } else if(RPRI != None && RPRI.HasAbility(class'Ability_ComboSuperSpeed') > 0 && InStr(ComboName, "Speed") >= 0) {
        //this bot was told to do the speed combo, but has super speed - use that instead!
        return string(class'ComboSuperSpeed');
    } else {
        return Super.NewRecommendCombo(ComboName, C);
    }
}

function ServerTraveling(string URL, bool bItems)
{
	//Save data again, as people might have bought something after the game ended
	SaveData();
	
	Super.ServerTraveling(URL, bItems);
}

function Mutate(string MutateString, PlayerController Sender)
{
	local array<string> Args;
	local bool bIsAdmin, bIsSuperAdmin;
	local int i, x;
	local class<RPGArtifact> ArtifactClass;
	local RPGWeaponModifier WM;
	local class<RPGWeaponModifier> WMClass;
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
	local Inventory Inv;
	local bool bAll;
	local string Game;
	local Pawn Cheat;
	local Controller CheatController;
	local Monster M;
	local class<RPGEffect> EffectClass;
	local RPGEffect Effect;
    local RPGArtifact A;
	
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
				Rules.bDamageLog = !Rules.bDamageLog;
				
				if(Rules.bDamageLog)
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
						if(C.Pawn != None && (bAll || Args[1] ~= C.GetHumanReadableName()))
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
		
		//only superadmin
		if(bIsSuperAdmin)
		{
			if(Args[0] ~= "travel" && Args.Length > 1)
			{
				if(Args.Length > 2)
					Game = Args[2];
				else
					Game = string(Level.Game.class);
				
				Level.ServerTravel(Args[1] $ "?Game=" $ Game $ "?Mutator=TitanRPG.MutTitanRPG", false);
				return;
			}
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
			else if(Args[0] ~= "nextwave" && Level.Game.IsA('Invasion'))
			{
				//Kill all monsters
				foreach DynamicActors(class'Monster', M)
				{
					if(FriendlyMonsterController(M.Controller) == None)
						M.Suicide();
				}
				
				//End wave
				Invasion(Level.Game).NumMonsters = 0;
				Invasion(Level.Game).WaveEndTime = Level.TimeSeconds;
				Invasion(Level.Game).bWaveInProgress = false;
				Invasion(Level.Game).WaveCountDown = 15;
				Invasion(Level.Game).WaveNum++;
			}
			else if(Cheat != None && (Args[0] ~= "make" || Args[0] ~= "wm") && Args.Length > 1)
			{
                if(Args[1] ~= "None") {
                    class'RPGWeaponModifier'.static.RemoveModifier(Cheat.Weapon);
                } else {
                    WMClass = class<RPGWeaponModifier>(DynamicLoadObject(PackageName $ ".WeaponModifier_" $ Args[1], class'Class'));
                    if(WMClass != None) {
                        x = WMClass.static.GetRandomModifierLevel();
                    
                        if(Args.Length > 2 && Args[2] != "")
                            x = int(Args[2]);
                    
                        WM = WMClass.static.Modify(
                            Cheat.Weapon, x, true, true);
                    }
                    else {
                        Sender.ClientMessage("WeaponModifier class '" $ Args[1] $ "' not found!");
                    }
                }
				return;
			}
            else if(Cheat != None && Args[0] ~= "cd")
            {
                for(Inv = Cheat.Inventory; Inv != None; Inv = Inv.Inventory) {
                    A = RPGArtifact(Inv);
                    if(A != None) {
                        A.NextUseTime = Level.TimeSeconds - 1;
                        A.ClientNotifyCooldown(-1);
                    }
                }
            }
			else if(Cheat != None && Args[0] ~= "effect" && Args.Length > 1)
			{
				EffectClass = class<RPGEffect>(DynamicLoadObject(PackageName $ ".Effect_" $ Args[1], class'Class'));
				if(EffectClass != None)
				{
					Effect = EffectClass.static.Create(Cheat, Sender);
					if(Effect != None)
						Effect.Start();
					else
						Sender.ClientMessage("Effect '" $ Args[1] $ "' not applicable.");
				}
				else
				{
					Sender.ClientMessage("Effect class '" $ Args[1] $ "' not found!");
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
				ArtifactClass = class<RPGArtifact>(DynamicLoadObject(PackageName $ ".Artifact_" $ Args[1], class'Class'));
				if(ArtifactClass != None)
					class'Util'.static.GiveInventory(Cheat, ArtifactClass);
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

	Super.GetServerDetails(ServerState);

	KVP.Key = "TitanRPG Version";
	
    if(Len(CustomVersion) > 0) {
        KVP.Value = CustomVersion;
    } else {
        KVP.Value = FriendlyName;
    }
    
	ServerState.ServerInfo[ServerState.ServerInfo.Length] = KVP;
}

defaultproperties
{
	bLevelCap=True
    MaxLevelReqExpPerLevel=0

	MinHumanPlayersForExp=0
	bAllowCheats=False
	MaxMonsters=1
	MaxTurrets=1
	MaxMines=8
    MaxTotems=1
	bAutoAdjustInvasionLevel=True
	InvasionAutoAdjustFactor=0.30
	SaveDuringGameInterval=0
	StartingLevel=1
	StartingStatPoints=0
	PointsPerLevel=5
	LevelDiffExpGainDiv=100.00
	MaxLevelupEffectStacking=1
	SuperAmmoClasses(0)=class'XWeapons.RedeemerAmmo'
	SuperAmmoClasses(1)=class'XWeapons.BallAmmo'
	SuperAmmoClasses(2)=class'XWeapons.TransAmmo'
	bAddToServerPackages=True
	GroupName="TitanRPG"
	FriendlyName="TitanRPG 1.71 BETA" //also used in Server Browser
    CustomVersion=""
	Description="A unified and heavily improved version of UT2004RPG and DruidsRPG, featuring a lot of new content, multi-game support and fixes of many bugs and other problems."
	SecondTextSingular="second"
	SecondTextPlural="seconds"
}
