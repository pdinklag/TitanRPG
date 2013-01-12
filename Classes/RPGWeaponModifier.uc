/*
	FINALLY getting rid of RPGWeapon. This is the future.
*/
class RPGWeaponModifier extends ReplicationInfo abstract
	Config(TitanRPG);

//Weapon
var Weapon Weapon;
var RPGPlayerReplicationInfo RPRI;
var bool bActive;

//Modifier level
var config int MinModifier, MaxModifier;
var bool bCanHaveZeroModifier;

var int Modifier;

//Bonus
var config float DamageBonus, BonusPerLevel;

//Visual
var bool bIdentified;
var Material ModifierOverlay;

//Overlay Sync (server only)
var bool bUpdateOverlay;
var Sync_OverlayMaterial SyncFirstPerson, SyncThirdPerson;

//Item name
var localized string PatternPos, PatternNeg;

//AI
var float AIRatingBonus;
var array<class<DamageType> > CountersDamage;
var array<class<RPGWeaponModifier> > CountersModifier;

//Restrictions
var config array<class<Weapon> > ForbiddenWeaponTypes;
var config bool bAllowForSpecials; //inventory groups 0 (super weapons) and 10 (xloc)
var bool bCanThrow;

//Description
var bool bOmitModifierInName;
var localized string DamageBonusText;
var string Description;

//Sync
var bool bDelayedIdentify; //used when granted on spawn

replication
{
    reliable if(Role == ROLE_Authority && bNetInitial)
        Weapon;

	reliable if(Role == ROLE_Authority && bNetDirty)
		bActive, Modifier, DamageBonus, BonusPerLevel, bIdentified;
    
	reliable if(Role == ROLE_Authority)
		ClientSetInstigator, ClientStartEffect, ClientStopEffect, ClientConstructItemName;
}

static function bool AllowedFor(class<Weapon> WeaponType, optional Pawn Other)
{
    if(class'Util'.static.InArray(WeaponType, class'MutTitanRPG'.default.DisallowModifiersFor) >= 0)
        return false;

	if(!default.bAllowForSpecials &&
		(
			WeaponType.default.InventoryGroup == 0 || //Super weapons
			WeaponType.default.InventoryGroup == 10 || //Translocator
			WeaponType.default.InventoryGroup == 15 //Ball Launcher
		)
	)
	{
		return false;
	}

	return (class'Util'.static.InArray(WeaponType, default.ForbiddenWeaponTypes) == -1);
}

static function RPGWeaponModifier Modify(Weapon W, int Modifier, optional bool bIdentify, optional bool bForce)
{
	local RPGWeaponModifier WM;
	
	if(!bForce && !AllowedFor(W.class, W.Instigator))
		return None;
	
    RemoveModifier(W); //remove existing
	
	WM = W.Spawn(default.class, W);
	if(WM != None) {
        if(Modifier == -100) {
            //Random
            Modifier = GetRandomModifierLevel();
        }

        WM.SetModifier(Modifier);

        if(bIdentify) {
            WM.Identify(false, true);
        }
    }

	return WM;
}

static function RemoveModifier(Weapon W) {
    local RPGWeaponModifier WM;

    WM = GetFor(W, true);
    if(WM != None) {
        WM.Destroy();
    }
}

static function RPGWeaponModifier GetFor(Weapon W, optional bool bAny)
{
	local RPGWeaponModifier WM;

	if(W != None) {
		foreach W.ChildActors(class'RPGWeaponModifier', WM) {
            if(bAny || ClassIsChildOf(WM.class, default.class)) {
                return WM;
            }
        }
	}
	return None;
}

static function string ConstructItemName(class<Weapon> WeaponClass, int Modifier)
{
	local string NewItemName;
	local string Pattern;
    
	if(default.PatternNeg == "")
		default.PatternNeg = default.PatternPos;
	
	if(Modifier >= 0)
		Pattern = default.PatternPos;
	else if(Modifier < 0)
		Pattern = default.PatternNeg;
	
	NewItemName = repl(Pattern, "$W", WeaponClass.default.ItemName);
	
	if(!default.bOmitModifierInName)
	{
		if(Modifier > 0)
			NewItemName @= "+" $ Modifier;
		else if(Modifier < 0)
			NewItemName @= Modifier;
	}

	return NewItemName;
}

static function int GetRandomModifierLevel()
{
	local int x;

	if(default.MinModifier == 0 && default.MaxModifier == 0)
		return 0;

	x = Rand(default.MaxModifier + 1 - default.MinModifier) + default.MinModifier;
	
	if(x == 0 && !default.bCanHaveZeroModifier)
		x = 1;
		
	return x;
}

static function int GetRandomPositiveModifierLevel()
{
	if(default.MaxModifier <= 0)
		return 0;
	else
		return Rand(default.MaxModifier) + 1;
}

function SetModifier(int x, optional bool bIdentify)
{
	local bool bWasActive;
	
	bWasActive = bActive;
	if(bActive)
		SetActive(false);

	Modifier = x;
	
	if(Modifier < 0 || Modifier > MaxModifier)
		Weapon.bCanThrow = false; //cannot throw negative or enhanced weapons
	else
		Weapon.bCanThrow = Weapon.default.bCanThrow && bCanThrow;
	
    if(bIdentify) {
        Identify(true);
    } else if(bIdentified) {
		Weapon.ItemName = ConstructItemName(Weapon.class, Modifier);
		ClientConstructItemName(Modifier);
	}
	
	if(bWasActive)
		SetActive(true);
}

simulated function ClientConstructItemName(int SyncModifier)
{
	if(Role < ROLE_Authority) {
        if(Weapon != None) {
            Weapon.ItemName = ConstructItemName(Weapon.class, SyncModifier);
            Description = "";
        } else {
            Warn("No weapon!");
        }
    }
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if(Role == ROLE_Authority)
	{
		Weapon = Weapon(Owner);
		if(Weapon == None)
		{
			Warn("Weapon Modifier without a weapon!");
			Destroy();
			return;
		}
		
		Weapon.bCanThrow = bCanThrow;
		Instigator = Weapon.Instigator;
        
        if(Instigator.PlayerReplicationInfo != None) {
            RPRI = class'RPGPlayerReplicationInfo'.static.GetForPRI(Instigator.PlayerReplicationInfo);
        } else {
            RPRI = None;
        }
	}
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	
	if(Role < ROLE_Authority) {
		SetOwner(Weapon);
    }
}

simulated event Tick(float dt) {
	if(Role == ROLE_Authority) {
		if(Weapon == None) {
			SetActive(false);
			Destroy();
			return;
		}
        
        if(bDelayedIdentify) {
            bDelayedIdentify = false;
            Identify(true, true);
        }
        
		if(Instigator != None) {
			if(!bActive && Instigator.Weapon == Weapon) {
				SetActive(true);
			} else if(bActive && Instigator.Weapon != Weapon) {
				SetActive(false);
            }
		} else if(bActive) {
			SetActive(false);
		}
		
		if(bActive)
			RPGTick(dt);
	}
    
    if(Role < ROLE_Authority || Level.NetMode == NM_Standalone) {
        if(bActive) {
            if(Weapon != None) {
                ClientRPGTick(dt);
            } else {
                Destroy();
            }
        }
    }
}

function Identify(optional bool bReIdentify, optional bool bOmitMessage)
{
	if(!bIdentified || bReIdentify)
	{
		Weapon.ItemName = ConstructItemName(Weapon.class, Modifier);
		ClientConstructItemName(Modifier);

		if(bActive)
		{
			SetOverlay();
		}
        
        if(!bOmitMessage && Instigator.Controller.IsA('PlayerController')) {
            PlayerController(Instigator.Controller).ReceiveLocalizedMessage(
                class'LocalMessage_NewIdentify', 0,,, Self);
        }

		bIdentified = true;
	}
}

function SetActive(bool bActivate)
{
	if(bActivate && !bActive)
	{
		StartEffect();
		
		if(bIdentified)
			SetOverlay();
		
        ClientSetInstigator();
		ClientStartEffect();
	}
	else if(!bActivate && bActive)
	{
		StopEffect();
		ClientStopEffect();
	}
	
	bActive = bActivate;
}

function SetOverlay()
{
    if(SyncFirstPerson != None)
        SyncFirstPerson.Destroy();

    SyncFirstPerson = class'Sync_OverlayMaterial'.static.Sync(Weapon, ModifierOverlay, -1, true);
    
    if(SyncThirdPerson != None)
        SyncThirdPerson.Destroy();
    
    if(WeaponAttachment(Weapon.ThirdPersonActor) != None) {
        SyncThirdPerson = class'Sync_OverlayMaterial'.static.Sync(Weapon.ThirdPersonActor, ModifierOverlay, -1, true);
    }
}

//interface
function StartEffect(); //weapon gets drawn
function StopEffect(); //weapon gets put down

simulated function ClientSetInstigator() {
    Instigator = Weapon.Instigator;
}

simulated function ClientStartEffect();
simulated function ClientStopEffect();

simulated function PostRender(Canvas C); //called client-side by the Interaction

function RPGTick(float dt); //called only if weapon is active
simulated function ClientRPGTick(float dt);

//TODO hook
function WeaponFire(byte Mode); //called when weapon just fired

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(DamageBonus != 0 && Modifier != 0)
		Damage += float(Damage) * Modifier * DamageBonus;
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType);

function bool PreventDeath(Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	return false;
}

function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier)
{
	return true;
}

function float GetAIRating() {
    local RPGBot B;
    local int x;
    local float Rating;

    Rating = Weapon.GetAIRating();

    if(MaxModifier == 0) {
        Rating += AIRatingBonus;
    } else {
        Rating += AIRatingBonus * Modifier;
    }

    Rating += DamageBonus * Modifier;

    B = RPGBot(Instigator.Controller);
    if(B != None) {
        if(B.LastModifierSuffered != None) {
            for(x = 0; x < CountersModifier.Length; x++) {
                if(CountersModifier[x] == B.LastModifierSuffered) {
                    Rating *= 2.5;
                    break;
                }
            }
        }

        if(B.LastDamageTypeSuffered != None) {
            for(x = 0; x < CountersDamage.Length; x++) {
                if(CountersDamage[x] == B.LastDamageTypeSuffered) {
                    Rating *= 2.5;
                    break;
                }
            }
        }
    }
    
    return Rating;
}

simulated event Destroyed()
{
    SetActive(false);
	Super.Destroyed();
}

simulated function AddToDescription(string Format, optional float Bonus)
{
	if(Description != "")
		Description $= ", ";
		
	if(Bonus != 0)
		Description $= Repl(Format, "$1", GetBonusPercentageString(Bonus));
	else
		Description $= Format;
}

simulated function BuildDescription()
{
	if(DamageBonus != 0)
		AddToDescription(DamageBonusText, DamageBonus);
}

simulated function string GetDescription()
{
	if(Description == "")
		BuildDescription();

	return Description;
}

//Helper function
simulated function string GetBonusPercentageString(float Bonus)
{
	local string text;

	Bonus *= float(Modifier);
	
	if(Bonus > 0)
		text = "+";
	
	Bonus *= 100.0f;
	
	if(float(int(Bonus)) == Bonus)
		text $= int(Bonus);
	else
		text $= Bonus;
	
	text $= "%";
	
	return text;
}

defaultproperties
{
	DamageBonusText="$1 damage"

	DamageBonus=0
	BonusPerLevel=0

	bCanThrow=True
	bCanHaveZeroModifier=True
	
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=4.00
	bAlwaysRelevant=False
	bOnlyRelevantToOwner=True
	bSkipActorPropertyReplication=True
	bOnlyDirtyReplication=True
	bReplicateMovement=False
	bReplicateInstigator=False //gotta do that myself
	bMovable=False
	bHidden=True
	
	bAllowForSpecials=True
	
	AIRatingBonus=0
}
