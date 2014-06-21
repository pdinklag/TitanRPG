//An ability a player can buy with stat points
//Abilities are handled similarly to DamageTypes and LocalMessages (abstract to avoid replication)
class RPGAbility extends Actor
	config(TitanRPG);

var localized string
	AndText, OrText, ReqPreText, ReqPostText,
	ForbPreText, ForbPostText, CostPerLevelText, MaxLevelText, ReqLevelText,
	AtLevelText, GrantPreText, GrantPostText;

//game-type specific disabling
var bool bAllowed;

var localized string AbilityName, StatName;
var localized string Description;
var localized array<string> LevelDescription;

var config int StartingCost, CostAddPerLevel, MaxLevel;
var config bool bUseLevelCost;
var config array<int> LevelCost;
var config array<int> RequiredLevels;

struct AbilityStruct
{
	var class<RPGAbility> AbilityClass;
	var int Level;
};
var config bool bDisjunctiveRequirements; //true = logical OR, false = logical AND
var config array<AbilityStruct> RequiredAbilities;
var config array<AbilityStruct> ForbiddenAbilities;

struct GrantItemStruct
{
	var int Level;
	var class<Inventory> InventoryClass;
};
var config array<GrantItemStruct> GrantItem;

//there is a bonus per level variable declared in so many abilities, I'm just moving it here
var config float BonusPerLevel; //general purpose

//Stats redux
var bool bIsStat; //set internally

var localized string StatDescription;

//Replication
var int Index, BuyOrderIndex;
var RPGPlayerReplicationInfo RPRI;
var int AbilityLevel;

var bool bClientReceived;

//Category
var class<RPGAbilityCategory> Category;

//Status icons
var class<RPGStatusIcon> StatusIconClass;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		RPRI, AbilityLevel, Index, BuyOrderIndex, bAllowed;
	
	reliable if(Role == ROLE_Authority)
		bIsStat;
	
	reliable if(Role < ROLE_Authority)
		ServerRequestConfig;
	
	reliable if(Role == ROLE_Authority)
		ClientReceiveRequired, ClientReceiveForbidden, ClientReceiveLevelCost,
		ClientReceiveReqLevel, ClientReceiveGrantedItem, ClientReceiveBasicSettings;
}

function ServerRequestConfig()
{
	local int i;
	
	ClientReceiveBasicSettings(StartingCost, CostAddPerLevel, MaxLevel, bUseLevelCost, BonusPerLevel, bDisjunctiveRequirements);

	for(i = 0; i < RequiredAbilities.Length; i++)
		ClientReceiveRequired(i, RequiredAbilities[i]);
		
	for(i = 0; i < ForbiddenAbilities.Length; i++)
		ClientReceiveForbidden(i, ForbiddenAbilities[i]);

	for(i = 0; i < GrantItem.Length; i++)
		ClientReceiveGrantedItem(i, GrantItem[i]);
		
	for(i = 0; i < RequiredLevels.Length; i++)
		ClientReceiveReqLevel(i, RequiredLevels[i]);

	if(bUseLevelCost)
	{
		for(i = 0; i < LevelCost.Length; i++)
			ClientReceiveLevelCost(i, LevelCost[i]);
	}
}

simulated function ClientReceiveBasicSettings(
	int xStartingCost, int xCostAddPerLevel, int xMaxLevel, bool xbUseLevelCost, float xBonusPerLevel, bool xbDisjunctiveRequirements)
{
	StartingCost = xStartingCost;
	CostAddPerLevel = xCostAddPerLevel;
	MaxLevel = xMaxLevel;
	bUseLevelCost = xbUseLevelCost;
	BonusPerLevel = xBonusPerLevel;
    bDisjunctiveRequirements = xbDisjunctiveRequirements;
}

simulated function ClientReceived()
{
	RPRI.ReceiveAbility(Self);
	bClientReceived = true;
	
	ServerRequestConfig();
	
	RequiredAbilities.Length = 0;
	ForbiddenAbilities.Length = 0;
	RequiredLevels.Length = 0;
	LevelCost.Length = 0;
	GrantItem.Length = 0;
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if(Role < ROLE_Authority && !bClientReceived && RPRI != None)
		ClientReceived();
}

simulated event Tick(float dt)
{
	Super.Tick(dt);
	
	if(Role < ROLE_Authority && !bClientReceived && RPRI != None)
		ClientReceived();
}

simulated event PostBeginPlay()
{
    local int i;
    local class<Inventory> InventoryClass;

	if(StatName == "")
		StatName = AbilityName;

	if(Role == ROLE_Authority) {
		bAllowed = class'MutTitanRPG'.static.Instance(Level).GameSettings.AllowAbility(Self.class);
        
        for(i = 0; i < GrantItem.Length; i++) {
            InventoryClass = Level.Game.BaseMutator.GetInventoryClass(string(GrantItem[i].InventoryClass));
            if(InventoryClass != None) {
                GrantItem[i].InventoryClass = InventoryClass;
            }
        }
    }

	if(Level.NetMode == NM_Standalone)
		RPRI.ReceiveAbility(Self); //make sure RPG menu gets enabled in offline games
	
	Super.PostBeginPlay();
}

simulated function ClientReceiveRequired(int i, AbilityStruct Req)
{
	RequiredAbilities[i] = Req;
}

simulated function ClientReceiveForbidden(int i, AbilityStruct Forbidden)
{
	ForbiddenAbilities[i] = Forbidden;
}

simulated function ClientReceiveReqLevel(int i, int lv)
{
	RequiredLevels[i] = lv;
}

simulated function ClientReceiveLevelCost(int i, int Cost)
{
	LevelCost[i] = Cost;
}

simulated function ClientReceiveGrantedItem(int i, GrantItemStruct Grant)
{
	GrantItem[i] = Grant;
}

simulated function bool Buy(optional int Amount)
{
	local int NextCost;
	
	Amount = Min(Amount, MaxLevel - AbilityLevel);

	if(bIsStat)
		NextCost = StartingCost * Amount;
	else
		NextCost = Cost();

	if(NextCost <= 0 || NextCost > RPRI.PointsAvailable)
		return false;

	RPRI.PointsAvailable -= NextCost;
	
	if(class'Util'.static.InArray(Self, RPRI.Abilities) == -1)
	{
		BuyOrderIndex = RPRI.Abilities.Length;
		RPRI.Abilities[RPRI.Abilities.Length] = Self;
	}

	if(bIsStat)
		AbilityLevel += Amount;
	else
		AbilityLevel++;

	if(Level.NetMode != NM_DedicatedServer)
		RPRI.ClientReInitMenu();

	if(Role == ROLE_Authority && bAllowed && RPRI.Controller.Pawn != None)
	{
		RPRI.ModifyStats();
	
		if(RPRI.Controller.Pawn.IsA('Vehicle'))
		{
			ModifyPawn(Vehicle(RPRI.Controller.Pawn).Driver);
			ModifyVehicle(Vehicle(RPRI.Controller.Pawn));
		}
		else
		{
			ModifyPawn(RPRI.Controller.Pawn);
		}
		
		RPRI.ProcessGrantQueue(); //give weapons
		
		if(RPRI.Controller.Pawn.Weapon != None)
			ModifyWeapon(RPRI.Controller.Pawn.Weapon);
	}
	return true;
}

//Get the ability's name
simulated function string GetName()
{
	if(bIsStat)
		return StatName;
	else
		return AbilityName;
}

/*
	Automatically generates a description text for this ability.
	Includes the Description string, items granted at certain levels, requirements, forbidden abilities, max level and
	finally the cost per level.
*/
simulated function string DescriptionText()
{
	local int x, lv, i;
	local array<string> list;
	local string text;
	
	text = Description;
	
	for(lv = 0; lv < MaxLevel && lv < LevelDescription.Length; lv++)
	{
		if(LevelDescription[lv] != "")
			text $= "|" $ LevelDescription[lv];
	}

	for(lv = 1; lv <= MaxLevel; lv++)
	{
		list.Remove(0, list.Length);
		for(x = 0; x < GrantItem.Length; x++)
		{
			if(GrantItem[x].InventoryClass != None && GrantItem[x].Level == lv)
				list[list.Length] = GrantItem[x].InventoryClass.default.ItemName;
		}
		
		if(list.Length > 0)
		{
			text $= "|" $ AtLevelText @ string(lv) $ GrantPreText;
			for(x = 0; x < list.Length; x++)
			{
				text @= list[x];
				
				if(x + 2 < list.Length)
					text $= ",";
				else if(x + 1 < list.Length)
					text @= AndText;
			}
			text @= GrantPostText;
		}
	}

	list.Remove(0, list.Length);
	
	/*
	TODO
	
	if(RequiredLevel > 0)
		list[list.Length] = ReqLevelText @ string(RequiredLevel);
	*/

	for(x = 0; x < RequiredAbilities.Length && RequiredAbilities[x].AbilityClass != None; x++)
	{
		i = list.Length;
		list[i] = RPRI.GetAbility(RequiredAbilities[x].AbilityClass).GetName();
		
		if(RequiredAbilities[x].Level > 1)
			list[i] @= string(RequiredAbilities[x].Level);
	}

	if(list.Length > 0)
	{
		text $= "||" $ ReqPreText;
		
		for(x = 0; x < list.Length; x++)
		{
			text @= list[x];
			
            if(x + 2 < list.Length) {
                text $= ",";
            } else if(x + 1 < list.Length) {
                if(bDisjunctiveRequirements) {
                    text @= OrText;
                } else {
                    text @= AndText;
                }
            }
		}
		
		text @= ReqPostText;
	}
	
	list.Remove(0, list.Length);
	for(x = 0; x < ForbiddenAbilities.Length && ForbiddenAbilities[x].AbilityClass != None; x++)
	{
		i = list.Length;
		list[i] = RPRI.GetAbility(ForbiddenAbilities[x].AbilityClass).GetName();
		
		if(ForbiddenAbilities[x].Level > 1)
			list[i] @= string(ForbiddenAbilities[x].Level);
	}

	if(list.Length > 0)
	{
		text $= "||" $ ForbPreText;
		
		for(x = 0; x < list.Length; x++)
		{
			text @= list[x];
			
			if(x + 2 < list.Length)
				text $= ",";
			else if(x + 1 < list.Length)
				text @= OrText;
		}
		
		text @= ForbPostText;
	}
	
	text $= "||" $ MaxLevelText $ ":" @ string(MaxLevel) $ "|" $ CostPerLevelText;
	for(x = 0; x < MaxLevel; x++)
	{
		text @= string(CostForNextLevel(x));
		
		if(x + 1 < MaxLevel)
			text $= ",";
	}
	
	return text;
}

//for stats
simulated function string StatDescriptionText()
{
	return StatDescription;
}

simulated function int CostForNextLevel(int x)
{
	//return a cost
	if(bIsStat)
	{
		return StartingCost; //stats have a constant cost
	}
	else
	{
		if(bUseLevelCost)
		{
			if(x < LevelCost.length)
			{
				return LevelCost[x];
			}
			else
			{
				Warn("LevelCost of ability" @ string(default.class) @ "does not provide enough entries for a MaxLevel of" @ string(default.MaxLevel));
				return LevelCost[LevelCost.Length - 1];
			}
		}
		else
		{
			return StartingCost + CostAddPerLevel * x;
		}
	}
}

simulated function int Cost()
{
	local int x, lv;
    local bool bDisjunctiveResult;

	if(AbilityLevel >= MaxLevel)
		return 0;

	if(RPRI != None)
	{
		//check required levels
		if(AbilityLevel < RequiredLevels.Length && RPRI.RPGLevel < RequiredLevels[AbilityLevel])
			return 0;
	
		//find forbidden abilities
		for(x = 0; x < ForbiddenAbilities.length; x++)
		{
			lv = RPRI.HasAbility(ForbiddenAbilities[x].AbilityClass, true);
			
			if(lv >= ForbiddenAbilities[x].Level)
				return 0;
		}

		//look for required abilities
		for(x = 0; x < RequiredAbilities.length; x++)
		{
			lv = RPRI.HasAbility(RequiredAbilities[x].AbilityClass, true);
			
            if(lv < RequiredAbilities[x].Level) {
                return 0;
            } else if(bDisjunctiveRequirements) {
                bDisjunctiveResult = true;
                break;
            }
		}
        
        if(bDisjunctiveRequirements && !bDisjunctiveResult) {
            return 0;
        }
	}

	//return a cost
	return CostForNextLevel(AbilityLevel);
}

function ModifyRPRI()
{
}

function ModifyPawn(Pawn Other)
{
	local int x;
	
	Instigator = Other;
	
	if(StatusIconClass != None)
		RPRI.ClientCreateStatusIcon(StatusIconClass);
	
	for(x = 0; x < GrantItem.Length; x++)
	{
		if(AbilityLevel >= GrantItem[x].Level) {
            if(ClassIsChildOf(GrantItem[x].InventoryClass, class'Weapon')) {
                RPRI.QueueWeapon(class<Weapon>(GrantItem[x].InventoryClass), None, 0, 0, 0);
            } else {
                class'Util'.static.GiveInventory(Other, GrantItem[x].InventoryClass);
            }
        }
	}
}

/* Modify the owning player's current weapon. Called whenever the player's weapon changes.
 */
function ModifyWeapon(Weapon Weapon);

/* Modify any artifact item given to the player.
 */
function ModifyArtifact(RPGArtifact A);


/* Modify a monster summoned by the owning player (Master).
 */
function ModifyMonster(Monster M, Pawn Master);

/* Modify a turret constructed by the owning player.
 */
function ModifyTurret(Vehicle T, Pawn Other);

/* Modify a totem constructed by the owning player.
 */
function ModifyTotem(RPGTotem T, Pawn Other);

function ModifyVehicle(Vehicle V);

/* Remove any modifications to this vehicle, because the player is no longer driving it.
 */
function UnModifyVehicle(Vehicle V);

//Override ability to enter or leave a vehicle
function bool CanEnterVehicle(Vehicle V)
{
	return true;
}

/* React to damage about to be done to the injured player's pawn. Called by RPGRules.NetDamage()
 * Note that this is called AFTER the damage has been affected by Damage Bonus/Damage Reduction.
 * Also note that for any damage this is called on the abilities of both players involved.
 * Use bOwnedByInstigator to determine which pawn is the owner of this ability.
 */
//function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator);

/* Dealing damage - NOTE: InstigatedBy is not necessarily the Instigator but whatever is currently controlled by it! */
function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType);

/* Taking damage - NOTE: Injured is not necessarily the Instigator but whatever is currently controlled by it! */
function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType);

/* Killed another player */
function ScoreKill(Controller Killed, class<DamageType> DamageType);

/* Killed by another player */
function Killed(Controller Killer, class<DamageType> DamageType);

/* If this returns true, prevent Killed's death. Called by RPGRules.PreventDeath()
 * NOTE: If a GameRules before RPGRules prevents the death, this probably won't get called
 * bAlreadyPrevented will be true if a GameRules AFTER RPGRules, or an ability, has already prevented the death.
 * If bAlreadyPrevented is true, the return value of this function is ignored. This is called anyway so you have the
 * opportunity to prevent stacking of death preventing abilities (for example, by putting a marker inventory on Killed
 * so next time you know not to prevent his death again because it was already prevented once)
 */
function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	return false;
}

/* If this returns true, prevent boneName from being severed from Killed. You should return true here anytime you will be
 * returning true to PreventDeath(), above, as otherwise you will have live pawns running around with no head and other
 * amusing but gameplay-damaging phenomenon.
 */
function bool PreventSever(Pawn Killed, name boneName, int Damage, class<DamageType> DamageType)
{
	return false;
}

/* Called by RPGRules.OverridePickupQuery() and works exactly like that function - if this returns true,
 * bAllowPickup determines if item can be picked up (1 is yes, any other value is no)
 * NOTE: The first function to return true prevents all further abilities in the player's ability list
 * from getting this call on that particular Pickup. Therefore, to maintain maximum compatibility,
 * return true only if you're actually overriding the normal behavior.
 */
function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
	return false;
}

/*
    Called by RPGPlayerReplicationInfo when a weapon is about to be granted to the
    owning player. If this function returns true, the weapon will be granted with the applied.
    modifications. If it returns false, it will not be granted at all.
*/
function bool ModifyGrantedWeapon(class<Weapon> WeaponClass, out class<RPGWeaponModifier> ModifierClass, out int Modifier) {
    return true;
}

/*
    Called by RPGPlayerReplicationInfo when a weapon is about to be granted to the
    owning player. This is called after ModifyGrantedWeapon returned true or if
    the weapon is forced.
*/
function ModifyGrantedWeaponAmmo(class<Weapon> WeaponClass, out int Ammo1, out int Ammo2);

/*
	Called by RPGEffect when it is about to be applied.
	Returns whether or not this effect can be applied when this ability is being owned.
*/
function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier)
{
	return true;
}

defaultproperties
{
	Category=class'AbilityCategory_Misc'

	StartingCost=0
	CostAddPerLevel=0
	bUseLevelCost=False
    
    bDisjunctiveRequirements=False;
	
	AndText="and"
	OrText="or"
	ReqLevelText="Level"
	ReqPreText="You need at least"
	ReqPostText="in order to purchase this ability."
	ForbPreText="You cannot have this ability and"
	ForbPostText="at the same time."
	CostPerLevelText="Cost (per level):"
	MaxLevelText="Max Level"
	AtLevelText="At level"
	GrantPreText=", you are granted the"
	GrantPostText="when you spawn."
	
	DrawType=DT_None

	bAlwaysRelevant=False
	bOnlyRelevantToOwner=True
	bOnlyDirtyReplication=True
	NetUpdateFrequency=4.000000
	RemoteRole=ROLE_SimulatedProxy
}
