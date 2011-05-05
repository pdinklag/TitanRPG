//RPGWeapons are wrappers for normal weapons which pass all functions to the weapon it controls,
//possibly modifying things first. This allows for weapon modifiers in a way that's
//compatible with almost any weapon, as long as no part of that weapon tries to cast Pawn.Weapon (which will always fail)
//NOTE: Removed ChaosUT compability! -pd
class RPGWeapon extends Weapon
	DependsOn(RPGPlayerReplicationInfo)
	config(TitanRPG)
	HideDropDown
	CacheExempt;

var config int MinModifier, MaxModifier; // +1, +2, -1, -2, etc
var bool bCanHaveZeroModifier;

var float BerserkFireRateScale;

var bool bAddToOldWeapons; //If false, the weapon magic will not be saved in the character's meta data, ie if you drop it, you can go pickup a different magic (pickup / drop / pickup aka PDP)

var config float DamageBonus, BonusPerLevel; //generic bonus per level

var config array<class<Weapon> > ForbiddenWeaponTypes;

var localized string PatternPos, PatternNeg;
var localized string DamageBonusText;

var RPGPlayerReplicationInfo HolderRPRI;

var Weapon ModifiedWeapon;
var string ModifiedItemName;

var Material ModifierOverlay;
var int Modifier;
var bool bIdentified;
var int References; //number of UT2004RPG actors referencing this actor
var int SniperZoomMode; //sniper zoom hack
var int LastAmmoChargePrimary; //used to sync up AmmoCharge between multiple RPGWeapons modifying the same class of weapon

//for AI
var float AIRatingBonus;
var array<class<DamageType> > CountersDamage;
var array<class<RPGWeapon> > CountersMagic;

//RPG Timer
var float RPGTimerTime, RPGTimeCounter;
var bool bRPGTimer, bRPGTimerRepeat;

//Favorite
var bool bFavorite;

replication
{
	reliable if(bNetOwner && bNetDirty && Role == ROLE_Authority)
		ModifiedWeapon, Modifier, bIdentified;
	reliable if(bNetOwner && Role == ROLE_Authority)
		DamageBonus, BonusPerLevel, bFavorite;
	reliable if(Role == ROLE_Authority) //functions
		ClientScaleFireRate, ClientSetFireRateScale, ClientConstructItemName;
	reliable if(Role < ROLE_Authority)
		ChangeAmmo, ReloadMeNow, FinishReloading, ServerForceUpdate;
}

//Finally, a central static function for magic weapon making
static function RPGWeapon Make(Pawn Owner, class<Weapon> WeaponClass, class<RPGWeapon> ModifierClass, int ModifierLevel)
{
	local Weapon OldWeapon;
	local RPGWeapon Mod;
	
	OldWeapon = Owner.Weapon;
	if(OldWeapon != None)
	{
		//Spawn Modifier
		Mod = OldWeapon.Spawn(ModifierClass, Owner);
		if(Mod != None)
		{
			//Spawn new weapon and give it to Owner
			Mod.SetModifiedWeapon(OldWeapon.Spawn(WeaponClass, Owner), true);
			Mod.SetModifier(ModifierLevel);
			Mod.GiveTo(Owner);
		}
	}
	
	return Mod;
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int i;
	
	if(class'Util'.static.InArray(Weapon, class'MutTitanRPG'.default.DisallowModifiersFor) >= 0)
		return false;
	
	for(i = 0; i < default.ForbiddenWeaponTypes.Length; i++)
	{
		if(ClassIsChildOf(Weapon, default.ForbiddenWeaponTypes[i]))
			return false;
	}

	return true;
}

function SetModifier(int NewModifier)
{
	StopEffect();
	Modifier = NewModifier;
	StartEffect();
}

function ModifyProjectile(Projectile P);

function Generate(RPGWeapon ForcedWeapon)
{
	local int Count;

	if(ForcedWeapon != None)
	{
		Modifier = ForcedWeapon.Modifier;
	}
	else if (MaxModifier != 0 || MinModifier != 0)
	{
		do
		{
			Modifier = Rand(MaxModifier + 1 - MinModifier) + MinModifier;
			Count++;
		}
		until (Modifier != 0 || bCanHaveZeroModifier || Count > 1000)
	}
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

function int GetRandomPositiveModifierLevel()
{
	if(MaxModifier == 0)
		return 0;
	else
		return Rand(MaxModifier) + 1;
}

function SetModifiedWeapon(Weapon W, bool bIdentify)
{
	if(W == None)
	{
		Destroy();
		return;
	}
	
	ModifiedWeapon = W;
	ModifiedItemName = ModifiedWeapon.ItemName;
	
	SetWeaponInfo();
	
	if(bIdentify)
	{
		Instigator = None; //don't want to send an identify message to anyone here
		Identify();
	}
}

simulated function bool ShouldShowChargingBar()
{
	return ModifiedWeapon.bShowChargingBar;
}

simulated function SetWeaponInfo()
{
	local int x;

	ModifiedWeapon.Instigator = Instigator;
	ModifiedWeapon.SetOwner(Owner);
	
	ItemName = ModifiedItemName;
	AIRating = ModifiedWeapon.AIRating;
	InventoryGroup = ModifiedWeapon.InventoryGroup;
	GroupOffset = ModifiedWeapon.GroupOffset;
	IconMaterial = ModifiedWeapon.IconMaterial;
	IconCoords = ModifiedWeapon.IconCoords;
	Priority = ModifiedWeapon.Priority;
	PlayerViewOffset = ModifiedWeapon.PlayerViewOffset;
	DisplayFOV = ModifiedWeapon.DisplayFOV;
	EffectOffset = ModifiedWeapon.EffectOffset;
	bMatchWeapons = ModifiedWeapon.bMatchWeapons;
	bShowChargingBar = ShouldShowChargingBar();
	bCanThrow = ModifiedWeapon.bCanThrow;
	ExchangeFireModes = ModifiedWeapon.ExchangeFireModes;
	bNoAmmoInstances = ModifiedWeapon.bNoAmmoInstances;
	HudColor = ModifiedWeapon.HudColor;
	CustomCrossHairColor = ModifiedWeapon.CustomCrossHairColor;
	CustomCrossHairScale = ModifiedWeapon.CustomCrossHairScale;
	CustomCrossHairTextureName = ModifiedWeapon.CustomCrossHairTextureName;
	SniperZoomMode = -1;
	
	for (x = 0; x < NUM_FIRE_MODES; x++)
	{
		FireMode[x] = ModifiedWeapon.FireMode[x];
		Ammo[x] = ModifiedWeapon.Ammo[x];
		AmmoClass[x] = ModifiedWeapon.AmmoClass[x];
		
		if(
			FireMode[x].IsA('SniperZoom') ||
			FireMode[x].IsA('PainterZoom') ||
			FireMode[x].IsA('CUTSRZoom') ||
		    //FireMode[x].IsA('HeliosZoom') || - Mysterial supported aimbots? tse tse ~pd
			FireMode[x].IsA('LongrifleZoom') ||
			FireMode[x].IsA('PICZoom'))
		{
			SniperZoomMode = x;
		}
	}
}

function Identify(optional bool bReIdentify)
{
	if(bIdentified && !bReIdentify)
		return;

	bIdentified = true;
	
	ModifiedItemName = ConstructItemName(Modifier, ModifiedWeapon.class);
	ItemName = ModifiedItemName;
	
	if(Role == ROLE_Authority)
		ClientConstructItemName(Modifier, ModifiedWeapon.class);
	
	if(Instigator != None)
		Instigator.ReceiveLocalizedMessage(class'LocalMessage_Identify', 0, None, None, Self);

	if(ModifiedWeapon.OverlayMaterial == None)
		SetOverlayMaterial(ModifierOverlay, -1, true);
}

simulated function ClientConstructItemName(int SyncModifier, class<Weapon> SyncWeaponClass)
{
	ModifiedItemName = ConstructItemName(SyncModifier, SyncWeaponClass);
	ItemName = ModifiedItemName;
}

static function string ConstructItemName(int Modifier, class<Weapon> WeaponClass)
{
	local string NewItemName;
	local string Pattern;
	
	if(Modifier >= 0)
		Pattern = default.PatternPos;
	else if(Modifier < 0)
		Pattern = default.PatternNeg;
	
	NewItemName = repl(Pattern, "$W", WeaponClass.default.ItemName);
	
	if(Modifier > 0)
		NewItemName @= "+" $ Modifier;
	else if(Modifier < 0)
		NewItemName @= Modifier;

	if(!default.bAddToOldWeapons)
		NewItemName @= "*";
	
	return NewItemName;
}

//New interface to get extra information which is displayed below the weapon's name -pd
simulated function string GetWeaponNameExtra()
{
	if(DamageBonus != 0 && Modifier != 0)
		return Repl(DamageBonusText, "$1", GetBonusPercentageString(DamageBonus));
	else
		return ""; //no extra info for standard weapons
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

//return true to allow player to have w
function bool AllowRPGWeapon(RPGWeapon w)
{
	if (Class == w.Class && ModifiedWeapon.Class == w.ModifiedWeapon.Class && Modifier >= w.Modifier)
		return false;

	return true;
}

/*
	Do NOT use this for magic effects!
	It corrupts the RPG damaging chain of events!
*/

function AdjustPlayerDamage(out int Damage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	ModifiedWeapon.AdjustPlayerDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
}

/*
	Use these for magic weapon effects.
*/

function RPGAdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, Vector HitLocation, out vector Momentum, class<DamageType> DamageType);
function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local float DamageModifier;

	if(Damage > 0 && DamageBonus != 0)
	{
		DamageModifier = FMax(0.0, 1.0 + DamageBonus * float(Modifier));

		Damage = Max(1, int(float(Damage) * DamageModifier));
		Momentum *= DamageModifier;
	}
}

//This is used to prevent the RPGWeapon from getting destroyed until nothing needs it
function RemoveReference()
{
	References--;
	if (References <= 0)
		Destroy();
}

//Weapon functions

simulated function float ChargeBar()
{
	return ModifiedWeapon.ChargeBar();
}

simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
	ModifiedWeapon.GetAmmoCount(MaxAmmoPrimary, CurAmmoPrimary);
	if (AmmoClass[0] != None)
		MaxAmmoPrimary = MaxAmmo(0);
}

simulated function DrawWeaponInfo(Canvas C)
{
	ModifiedWeapon.DrawWeaponInfo(C);
}

simulated function NewDrawWeaponInfo(Canvas C, float YPos)
{
	ModifiedWeapon.NewDrawWeaponInfo(C, YPos);
}

function OwnerEvent(name EventName)
{
	if (EventName == 'ChangedWeapon' && Instigator.Weapon == self && ModifierOverlay != None && bIdentified)
	{
		ModifiedWeapon.SetOverlayMaterial(ModifierOverlay, 1000000, false);
		if (WeaponAttachment(ThirdPersonActor) != None)
			ThirdPersonActor.SetOverlayMaterial(ModifierOverlay, 1000000, false);
	}

	Super.OwnerEvent(EventName);
}

function float RangedAttackTime()
{
	return ModifiedWeapon.RangedAttackTime();
}

function bool RecommendRangedAttack()
{
	return ModifiedWeapon.RecommendRangedAttack();
}

function bool RecommendLongRangedAttack()
{
	return ModifiedWeapon.RecommendLongRangedAttack();
}

function bool FocusOnLeader(bool bLeaderFiring)
{
	return ModifiedWeapon.FocusOnLeader(bLeaderFiring);
}

function FireHack(byte Mode)
{
	ModifiedWeapon.FireHack(Mode);
}

function bool SplashDamage()
{
	return ModifiedWeapon.SplashDamage();
}

function bool RecommendSplashDamage()
{
	return ModifiedWeapon.RecommendSplashDamage();
}

function float GetDamageRadius()
{
	return ModifiedWeapon.GetDamageRadius();
}

function float RefireRate()
{
	return ModifiedWeapon.RefireRate();
}

function bool FireOnRelease()
{
	return ModifiedWeapon.FireOnRelease();
}

simulated function Loaded()
{
	ModifiedWeapon.Loaded();
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	Canvas.SetDrawColor(255,255,255);

	Canvas.DrawText("RPGWEAPON");
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawText("ModifiedWeapon: "$ModifiedWeapon);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	ModifiedWeapon.DisplayDebug(Canvas, YL, YPos);
}

simulated function Weapon RecommendWeapon( out float rating )
{
    local Weapon Recommended;
    local float oldRating;

    if ( (Instigator == None) || (Instigator.Controller == None) )
        rating = -2;
    else
        rating = RateSelf() + Instigator.Controller.WeaponPreference(ModifiedWeapon);

    if ( inventory != None )
    {
        Recommended = inventory.RecommendWeapon(oldRating);
        if ( (Recommended != None) && (oldRating > rating) )
        {
            rating = oldRating;
            return Recommended;
        }
    }
    return self;
}

function SetAITarget(Actor T)
{
	ModifiedWeapon.SetAITarget(T);
}

function byte BestMode()
{
	return ModifiedWeapon.BestMode();
}

function bool BotFire(bool bFinished, optional name FiringMode)
{
	local bool bResult;

	bResult = ModifiedWeapon.BotFire(bFinished, FiringMode);
	BotMode = ModifiedWeapon.BotMode;
	return bResult;
}

simulated function vector GetFireStart(vector X, vector Y, vector Z)
{
	return ModifiedWeapon.GetFireStart(X, Y, Z);
}

simulated function float AmmoStatus(optional int Mode)
{
	if (bNoAmmoInstances)
	{
		if (AmmoClass[Mode] == None)
			return 0;
		if (AmmoClass[0] == AmmoClass[mode])
			mode = 0;

		return float(ModifiedWeapon.AmmoCharge[Mode])/float(MaxAmmo(Mode));
	}
	if (Ammo[Mode] == None)
		return 0.0;
	else
		return float(Ammo[Mode].AmmoAmount) / float(Ammo[Mode].MaxAmmo);
}

simulated function float RateSelf()
{
	if(!HasAmmo())
		CurrentRating = -2;
	else if (Instigator == None || Instigator.Controller == None )
		return 0;
	else if(AIController(Instigator.Controller) != None)
		CurrentRating = Instigator.Controller.RateWeapon(Self); //allows RPGBot to evaluate the weapon magic
	else
		CurrentRating = Instigator.Controller.RateWeapon(ModifiedWeapon); //preserves a client's weapon order

	return CurrentRating;
}

function float GetAIRating()
{
	local RPGBot B;
	local int x;
	local float Rating;
	
	Rating = ModifiedWeapon.GetAIRating();
	
	if(MaxModifier == 0)
		Rating += AIRatingBonus;
	else
		Rating += AIRatingBonus * Modifier;

	Rating += DamageBonus * Modifier;

	B = RPGBot(Instigator.Controller);
	if(B != None)
	{
		if(B.LastWeaponMagicSuffered != None)
		{
			for(x = 0; x < CountersMagic.Length; x++)
			{
				if(CountersMagic[x] == B.LastWeaponMagicSuffered)
				{
					Rating *= 2.5;
					break;
				}
			}
		}
		
		if(B.LastDamageTypeSuffered != None)
		{
			for(x = 0; x < CountersDamage.Length; x++)
			{
				if(CountersDamage[x] == B.LastDamageTypeSuffered)
				{
					Rating *= 2.5;
					break;
				}
			}
		}
	}
	
	return Rating;
}

function float SuggestAttackStyle()
{
	return ModifiedWeapon.SuggestAttackStyle();
}

function float SuggestDefenseStyle()
{
	return ModifiedWeapon.SuggestDefenseStyle();
}

function bool SplashJump()
{
	return ModifiedWeapon.SplashJump();
}

function bool CanAttack(Actor Other)
{
	return ModifiedWeapon.CanAttack(Other);
}

simulated function Destroyed()
{
	DestroyModifiedWeapon();

	Super.Destroyed();
}

simulated function DestroyModifiedWeapon()
{
	local int i;

	//after ModifiedWeapon gets destroyed, the FireMode array will become bogus pointers since they're not actors
	//so have to manually set to None
	for (i = 0; i < NUM_FIRE_MODES; i++)
		FireMode[i] = None;

	if (ModifiedWeapon != None)
		ModifiedWeapon.Destroy();
}

simulated function Reselect()
{
	ModifiedWeapon.Reselect();
}

simulated function bool WeaponCentered()
{
	return ModifiedWeapon.WeaponCentered();
}

simulated event RenderOverlays(Canvas Canvas)
{

	ModifiedWeapon.RenderOverlays(Canvas);
}

simulated function PreDrawFPWeapon()
{
	ModifiedWeapon.PreDrawFPWeapon();
}

simulated function SetHand(float InHand)
{
	Hand = InHand;
	ModifiedWeapon.SetHand(Hand);
}

simulated function GetViewAxes(out vector xaxis, out vector yaxis, out vector zaxis)
{
	ModifiedWeapon.GetViewAxes(xaxis, yaxis, zaxis);
}

simulated function vector CenteredEffectStart()
{
	return ModifiedWeapon.CenteredEffectStart();
}

simulated function vector GetEffectStart()
{
	return ModifiedWeapon.GetEffectStart();
}

simulated function IncrementFlashCount(int Mode)
{
	ModifiedWeapon.IncrementFlashCount(Mode);
}

simulated function ZeroFlashCount(int Mode)
{
	ModifiedWeapon.ZeroFlashCount(Mode);
}

function HolderDied()
{
	ModifiedWeapon.HolderDied();

	// set the controller's last pawn weapon to modified weapon so stats work properly
	if (Instigator.Controller != None)
		Instigator.Controller.LastPawnWeapon = ModifiedWeapon.Class;
}

simulated function bool CanThrow()
{
	if (Modifier < 0 || Modifier > MaxModifier )
		return false; //can't throw cursed or enhanced weapons

	return bCanThrow && ModifiedWeapon.CanThrow(); //OneDropRPGWeapon says "return true;" here
}

simulated function GiveTo(Pawn Other, optional Pickup Pickup)
{
    local int m;
    local weapon w;
    local bool bPossiblySwitch, bJustSpawned;
    local Inventory Inv;

    Instigator = Other;
    ModifiedWeapon.Instigator = Other;
    for (Inv = Instigator.Inventory; true; Inv = Inv.Inventory)
    {
    	if (Inv.Class == ModifiedWeapon.Class || (RPGWeapon(Inv) != None && !RPGWeapon(Inv).AllowRPGWeapon(Self)))
    	{
		W = Weapon(Inv);
		break;
    	}
    	m++;
    	if (m > 1000)
    		break;
    	if (Inv.Inventory == None) //hack to keep Inv at last item in Instigator's inventory
    		break;
    }

    if ( W == None )
    {
	//hack - manually add to Instigator's inventory because pawn won't usually allow duplicates
	Inv.Inventory = self;
	Inventory = None;
	SetOwner(Instigator);
	if (Instigator.Controller != None)
		Instigator.Controller.NotifyAddInventory(self);

	bJustSpawned = true;
        ModifiedWeapon.SetOwner(Owner);
        bPossiblySwitch = true;
        W = self;
    }
    else if ( !W.HasAmmo() )
	    bPossiblySwitch = true;

    if ( Pickup == None )
        bPossiblySwitch = true;

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if ( ModifiedWeapon.FireMode[m] != None )
        {
            ModifiedWeapon.FireMode[m].Instigator = Instigator;
            W.GiveAmmo(m,WeaponPickup(Pickup),bJustSpawned);
        }
    }

	if ( (Instigator.Weapon != None) && Instigator.Weapon.IsFiring() )
		bPossiblySwitch = false;

	if ( Instigator.Weapon != W )
		W.ClientWeaponSet(bPossiblySwitch);

    if (Instigator.Controller != None && Instigator.Controller == Level.GetLocalPlayerController()) //can only do this on listen/standalone
    {
       	if (bIdentified)
		PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'LocalMessage_Identify', 1,,, self);
	else if (ModifiedWeapon.PickupClass != None)
	    	PlayerController(Instigator.Controller).ReceiveLocalizedMessage(ModifiedWeapon.PickupClass.default.MessageClass, 0,,,ModifiedWeapon.PickupClass);
    }

	SetHolderRPRI();

    if ( !bJustSpawned )
    {
        for (m = 0; m < NUM_FIRE_MODES; m++)
        {
            Ammo[m] = None;
            ModifiedWeapon.Ammo[m] = None;
        }
		Destroy();
    }
    else
    {
		for (m = 0; m < NUM_FIRE_MODES; m++)
			Ammo[m] = ModifiedWeapon.Ammo[m];
    }
	
	CheckFavorite();
}

function CheckFavorite()
{	
	if(HolderRPRI != None)
		bFavorite = HolderRPRI.IsFavorite(ModifiedWeapon.class, Self.class);
	else
		bFavorite = false;
	
	if(bFavorite)
		Log(Self.class @ "/" @ ModifiedWeapon.class $ ": This is a favorite weapon!", 'TitanRPG');
}

function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
	local Inventory Inv;
	local RPGWeapon W;

	ModifiedWeapon.GiveAmmo(m, WP, bJustSpawned);
	if (bNoAmmoInstances && FireMode[m].AmmoClass != None && (m == 0 || FireMode[m].AmmoClass != FireMode[0].AmmoClass))
	{
		if (bJustSpawned)
		{
			for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				W = RPGWeapon(Inv);
				if (W != None && W != self && W.bNoAmmoInstances && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
				{
					W.AddAmmo(ModifiedWeapon.AmmoCharge[m], m);
					W.SyncUpAmmoCharges();
					break;
				}
			}
		}
		else
			SyncUpAmmoCharges();
	}
}

simulated function SetHolderRPRI()
{
	HolderRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);

	if (HolderRPRI == None)
		Warn("Couldn't find RPRI for" @ Instigator.GetHumanReadableName() $ ", ModifiedWeapon =" @ ModifiedWeapon);
}

function SynchronizeWeapon(Weapon ClientWeapon)
{
	Super.SynchronizeWeapon(ClientWeapon);
}

simulated function ClientWeaponSet(bool bPossiblySwitch)
{
    local int Mode;

    Instigator = Pawn(Owner);

    bPendingSwitch = bPossiblySwitch;

    if( Instigator == None || ModifiedWeapon == None )
    {
        GotoState('PendingClientWeaponSet');
        return;
    }

    SetWeaponInfo();
    SetHolderRPRI();

    for( Mode = 0; Mode < NUM_FIRE_MODES; Mode++ )
    {
        if( ModifiedWeapon.FireModeClass[Mode] != None )
        {
            if (FireMode[Mode] == None || FireMode[Mode].AmmoClass != None && !bNoAmmoInstances && Ammo[Mode] == None && FireMode[Mode].AmmoPerFire > 0)
            {
                GotoState('PendingClientWeaponSet');
                return;
            }
        }

        FireMode[Mode].Instigator = Instigator;
        FireMode[Mode].Level = Level;
    }

    ClientState = WS_Hidden;
    ModifiedWeapon.ClientState = ClientState;
    GotoState('Hidden');

    if( Level.NetMode == NM_DedicatedServer || !Instigator.IsHumanControlled() )
        return;

    if( Instigator.Weapon == self || Instigator.PendingWeapon == self ) // this weapon was switched to while waiting for replication, switch to it now
    {
        if (Instigator.PendingWeapon != None)
		{
            Instigator.ChangedWeapon();
		}
        else
		{
            BringUp();
		}
        return;
    }

    if( Instigator.PendingWeapon != None && Instigator.PendingWeapon.bForceSwitch )
        return;

    if( Instigator.Weapon == None )
    {
        Instigator.PendingWeapon = self;
        Instigator.ChangedWeapon();
    }
    else if ( bPossiblySwitch )
    {
		if ( PlayerController(Instigator.Controller) != None && PlayerController(Instigator.Controller).bNeverSwitchOnPickup )
			return;
        if ( Instigator.PendingWeapon != None )
        {
            if ( RateSelf() > Instigator.PendingWeapon.RateSelf() )
            {
                Instigator.PendingWeapon = self;
                Instigator.Weapon.PutDown();
            }
        }
        else if ( RateSelf() > Instigator.Weapon.RateSelf() )
        {
            Instigator.PendingWeapon = self;
            Instigator.Weapon.PutDown();
        }
    }
}

function SetWeaponSpeed()
{
	local RPGPlayerReplicationInfo RPRI;

	if(Role == ROLE_Authority)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
		{
			SetFireRateScale(1.0f + 0.01f *  RPRI.WeaponSpeed);
		}
		else
		{
			//Instigator died?
			SetFireRateScale(1.0f);
		}
	}
}

simulated function Fire(float F)
{
	ModifiedWeapon.Fire(F);
}

simulated function AltFire(float F)
{
	ModifiedWeapon.AltFire(F);
}

simulated function SetRPGTimer(float Time, optional bool bRepeat)
{
	if(Time > 0)
	{
		bRPGTimer = true;
		RPGTimerTime = Time;
		RPGTimeCounter = Time;
		bRPGTimerRepeat = bRepeat;
	}
	else
	{
		bRPGTimer = false;
	}
}

//Override
function RPGTimer();

simulated event WeaponTick(float dt)
{
	local Pawn Enemy;
	local ShockProjectile ShockBall;
	local int x;
	
	//Failsafe to prevent losing sync with ModifiedWeapon
	if (AmmoClass[0] != ModifiedWeapon.AmmoClass[0])
	{
		for (x = 0; x < NUM_FIRE_MODES; x++)
		{
			FireMode[x] = ModifiedWeapon.FireMode[x];
			Ammo[x] = ModifiedWeapon.Ammo[x];
			AmmoClass[x] = ModifiedWeapon.AmmoClass[x];
		}
		ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}

	//sync up ammocharge with other RPGWeapons player has that are modifying the same class of weapon
	if (Role == ROLE_Authority && bNoAmmoInstances && LastAmmoChargePrimary != ModifiedWeapon.AmmoCharge[0])
	{
		SyncUpAmmoCharges();

		//isn't it ironic that my code in Weapon.uc for the latest patch that prevents erroneous switching to
		//best weapon screwed my own mod?
		//so now I need this hack to work around it
		if (!HasAmmo())
		{
			if (Instigator.IsLocallyControlled())
			{
				OutOfAmmo();
			}
			else
			{
				//force net update because client checks ammo in PostNetReceive()
				bClientTrigger = !bClientTrigger;
			}
		}
	}

	//Rocket launcher homing hack
	if(ModifiedWeapon.IsA('RocketLauncher'))
	{
		Instigator.Weapon = ModifiedWeapon;
		ModifiedWeapon.Tick(dt);
		Instigator.Weapon = self;
	}
	
	//Hack to enable bots to do shock combos with RPGWeapons
	if(
		Role == ROLE_Authority &&
		Instigator.Controller.IsA('AIController') &&
		Instigator.Controller.Enemy != None &&
		ModifiedWeapon.IsA('ShockRifle')
	)
	{
		if(ShockRifle(ModifiedWeapon).ComboTarget == None)
		{
			Enemy = Instigator.Controller.Enemy;
			foreach Enemy.VisibleCollidingActors(class'ShockProjectile', ShockBall, class'ShockProjectile'.default.ComboRadius)
			{
				if(ShockBall.Instigator == Instigator)
				{
					if(
						VSize(Enemy.Location - ShockBall.Location) <= 0.5 * ShockBall.ComboRadius + Enemy.CollisionRadius ||
						(Velocity Dot (Enemy.Location - ShockBall.Location)) <= 0
					)
					{
						ShockRifle(ModifiedWeapon).SetComboTarget(ShockBall);
						ShockRifle(ModifiedWeapon).bWaitForCombo = false; //don't wait, do it NOW
						ShockRifle(ModifiedWeapon).StartFire(0);
						break;
					}
				}
			}
		}
	}

	ModifiedWeapon.WeaponTick(dt);
	
	//Timer
	if(bRPGTimer)
	{
		RPGTimeCounter -= dt;
		if(RPGTimeCounter <= 0.0f)
		{
			RPGTimer();

			if(bRPGTimerRepeat)
				RPGTimeCounter += RPGTimerTime; //addition to compensate a little possible overtime
			else
				bRPGTimer = false;
		}
	}
}

function SetAmmo(int Mode, int Amount)
{
	if(bNoAmmoInstances)
	{
		if(Amount == -1)
			Amount = ModifiedWeapon.MaxAmmo(0);
	
		AmmoCharge[Mode] = Amount;
		ModifiedWeapon.AmmoCharge[Mode] = Amount;
	}
	else if(ModifiedWeapon.Ammo[Mode] != None)
	{
		if(Amount == -1)
			Amount = ModifiedWeapon.Ammo[Mode].MaxAmmo;
		
		ModifiedWeapon.Ammo[Mode].AmmoAmount = Amount;
		
		if(Ammo[Mode] != None)
			Ammo[Mode].AmmoAmount = Amount;
	}
}

function SyncUpAmmoCharges()
{
	local Inventory Inv;
	local RPGWeapon W;

	LastAmmoChargePrimary = ModifiedWeapon.AmmoCharge[0];

	for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = RPGWeapon(Inv);
		if (W != None && W != self && W.bNoAmmoInstances && W.ModifiedWeapon != None && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
		{
			W.ModifiedWeapon.AmmoCharge[0] = ModifiedWeapon.AmmoCharge[0];
			W.ModifiedWeapon.AmmoCharge[1] = ModifiedWeapon.AmmoCharge[1];
			W.LastAmmoChargePrimary = LastAmmoChargePrimary;
			W.ModifiedWeapon.NetUpdateTime = Level.TimeSeconds - 1;
		}
	}
}

simulated function OutOfAmmo()
{
	local int i;

	ModifiedWeapon.OutOfAmmo();

	//weapons with many ammo types, like ChaosUT weapons, might have switched firemodes/ammotypes here
	for (i = 0; i < NUM_FIRE_MODES; i++)
	{
		FireMode[i] = ModifiedWeapon.FireMode[i];
		Ammo[i] = ModifiedWeapon.Ammo[i];
		AmmoClass[i] = ModifiedWeapon.AmmoClass[i];
	}
	ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
}

simulated function ClientStartFire(int Mode)
{
	//HACK - sniper zoom
	if(Mode == SniperZoomMode)
	{
		FireMode[mode].bIsFiring = true;
		if( Instigator.Controller.IsA( 'PlayerController' ) )
			PlayerController(Instigator.Controller).ToggleZoom();
		
		return;
	}
	else if(RocketLauncher(ModifiedWeapon) != None) //HACK - rocket launcher spread
	{
		if(Mode == 1)
		{
			RocketLauncher(ModifiedWeapon).bTightSpread = false;
		}
		else if(FireMode[1].bIsFiring || (FireMode[1].NextFireTime > Level.TimeSeconds))
		{
			if ((FireMode[1].Load > 0) && !RocketLauncher(ModifiedWeapon).bTightSpread)
			{
				RocketLauncher(ModifiedWeapon).bTightSpread = true;
				RocketLauncher(ModifiedWeapon).ServerSetTightSpread();
			}
			return;
		}
	}

	Super.ClientStartFire(Mode);
}

simulated function bool StartFire(int Mode)
{
	if(ModifiedWeapon != None)
		return ModifiedWeapon.StartFire(Mode);
	else
		return false;
}

simulated event ClientStopFire(int Mode)
{
	ModifiedWeapon.ClientStopFire(Mode);
}

simulated function bool ReadyToFire(int Mode)
{
	return ModifiedWeapon.ReadyToFire(Mode);
}

simulated function Timer()
{
	local int Mode;

	if (ModifiedWeapon == None)
		return;

	ModifiedWeapon.Timer();

	// if the ModifiedWeapon thinks it should be hidden, verify that a weapon change actually occurred
	// (it would have checked Instigator.Weapon != self which always fails)
	if (ModifiedWeapon.ClientState == WS_Hidden && Instigator.Weapon == self)
	{
		// we didn't actually switch, so reset the ModifiedWeapon's state
		ModifiedWeapon.ClientState = WS_ReadyToFire;
		for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
		{
			FireMode[Mode].InitEffects();
		}
		PlayIdle();
	}

	ClientState = ModifiedWeapon.ClientState;
	if (ModifiedWeapon.TimerRate > 0)
	{
		SetTimer(ModifiedWeapon.TimerRate, false);
		ModifiedWeapon.SetTimer(0, false);
	}
}

simulated function bool IsFiring()
{
	return ModifiedWeapon.IsFiring();
}

function bool IsRapidFire()
{
	return ModifiedWeapon.IsRapidFire();
}

function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
	return ModifiedWeapon.ConsumeAmmo(Mode, load, bAmountNeededIsMax);
}

simulated function bool HasAmmo()
{
	if (ModifiedWeapon != None)
		return ModifiedWeapon.HasAmmo();

	return false;
}

//===
/*
	I'm finally sick of weapon speed bugs and berserk not working correctly.
	Every weapon fire rate scale should now happen via this function ONLY.
	
	It applies the fire rate on the server and makes sure the client receives the same data at the same time.
	
	-pd
*/
//===
function ScaleFireRate(float Scale) //scale
{
	if(Role == ROLE_Authority) //to make PERFECTLY sure
	{
		class'Util'.static.AdjustWeaponFireRate(ModifiedWeapon, Scale);
		ClientScaleFireRate(Scale);
	}
}

function SetFireRateScale(float Scale) //set (ie first reset to default)
{
	if(Role == ROLE_Authority) //to make PERFECTLY sure
	{
		class'Util'.static.SetWeaponFireRate(ModifiedWeapon, Scale);
		ClientSetFireRateScale(Scale);
	}
}

simulated function ClientSetFireRateScale(float Scale)
{
	class'Util'.static.SetWeaponFireRate(ModifiedWeapon, Scale);
}

simulated function ClientScaleFireRate(float Scale)
{
	class'Util'.static.AdjustWeaponFireRate(ModifiedWeapon, Scale);
}

/*
simulated function DoSetFireRateScale(float Scale)
{
	local int i;
	local WeaponFire WF;
	
	for(i = 0; i < NUM_FIRE_MODES; i++)
	{
		WF = ModifiedWeapon.GetFireMode(i);
		if(WF != None)
		{
			if(MinigunFire(WF) != None) //minigun needs a hack because it fires differently than normal weapons
			{
				MinigunFire(WF).BarrelRotationsPerSec = MinigunFire(WF).default.BarrelRotationsPerSec * Scale;
				MinigunFire(WF).FireRate = 1.f / (MinigunFire(WF).RoundsPerRotation * MinigunFire(WF).BarrelRotationsPerSec);
				MinigunFire(WF).MaxRollSpeed = 65536.f * MinigunFire(WF).BarrelRotationsPerSec;
			}
			else if(TransFire(WF) == None && BallShoot(WF) == None)
			{
				WF.FireRate = WF.default.FireRate / Scale;
				WF.FireAnimRate = WF.default.FireAnimRate * Scale;
				WF.ReloadAnimRate = WF.default.ReloadAnimRate * Scale;
				WF.MaxHoldTime = WF.default.MaxHoldTime / Scale;
				
				if(ShieldFire(WF) != None)
					ShieldFire(WF).FullyChargedTime = ShieldFire(WF).default.FullyChargedTime / Scale;
					
				if(BioChargedFire(WF) != None)
					BioChargedFire(WF).GoopUpRate = BioChargedFire(WF).default.GoopUpRate / Scale;
					
				if(PainterFire(WF) != None)
					PainterFire(WF).PaintDuration = PainterFire(WF).default.PaintDuration / Scale;
			}
		}
	}
}

simulated function DoScaleFireRate(float Scale)
{
	local int i;
	local WeaponFire WF;
	
	for(i = 0; i < NUM_FIRE_MODES; i++)
	{
		WF = ModifiedWeapon.GetFireMode(i);
		if(WF != None)
		{
			if(MinigunFire(WF) != None) //minigun needs a hack because it fires differently than normal weapons
			{
				MinigunFire(WF).BarrelRotationsPerSec *= Scale;
				MinigunFire(WF).FireRate = 1.f / (MinigunFire(WF).RoundsPerRotation * MinigunFire(WF).BarrelRotationsPerSec);
				MinigunFire(WF).MaxRollSpeed = 65536.f * MinigunFire(WF).BarrelRotationsPerSec;
			}
			else if(TransFire(WF) == None && BallShoot(WF) == None)
			{
				WF.FireRate /= Scale;
				WF.FireAnimRate *= Scale;
				WF.ReloadAnimRate *= Scale;
				WF.MaxHoldTime /= Scale;
				
				if(ShieldFire(WF) != None)
					ShieldFire(WF).FullyChargedTime /= Scale;
					
				if(BioChargedFire(WF) != None)
					BioChargedFire(WF).GoopUpRate /= Scale;
					
				if(PainterFire(WF) != None)
					PainterFire(WF).PaintDuration /= Scale;
			}
		}
	}
}
*/
//===

simulated function StartBerserk()
{
	//ModifiedWeapon.StartBerserk(); //bye bye buggy code -pd
	
	if((Level.GRI != None) && Level.GRI.WeaponBerserk > 1.0)
		return;
	
	bBerserk = true;
	
	ScaleFireRate(BerserkFireRateScale);
}

simulated function StopBerserk()
{
	//ModifiedWeapon.StopBerserk(); //bye bye buggy code -pd
	
	bBerserk = false;
	
	if((Level.GRI != None) && Level.GRI.WeaponBerserk > 1.0)
		return;
		
	ScaleFireRate(1.0f / BerserkFireRateScale);
}

simulated function AnimEnd(int channel)
{
	ModifiedWeapon.AnimEnd(channel);
}

simulated function PlayIdle()
{
	ModifiedWeapon.PlayIdle();
}

function bool CheckReflect(Vector HitLocation, out Vector RefNormal, int AmmoDrain)
{
	if(ModifiedWeapon != None)
		return ModifiedWeapon.CheckReflect(HitLocation, RefNormal, AmmoDrain);
	else
		return false;
}

function DoReflectEffect(int Drain)
{
	ModifiedWeapon.DoReflectEffect(Drain);
}

function bool HandlePickupQuery(pickup Item)
{
	//local WeaponPickup wpu;
	local int i;

	if (bNoAmmoInstances)
	{
		// handle ammo pickups
		for (i = 0; i < 2; i++)
		{
			if (Item.inventorytype == AmmoClass[i] && AmmoClass[i] != None)
			{
				if (ModifiedWeapon.AmmoCharge[i] >= MaxAmmo(i))
					return true;
				Item.AnnouncePickup(Pawn(Owner));
				AddAmmo(Ammo(Item).AmmoAmount, i);
				Item.SetRespawn();
				return true;
			}
		}
	}

	if (ModifiedWeapon != None && ModifiedWeapon.Class == Item.InventoryType)
	{
		return ModifiedWeapon.HandlePickupQuery(Item);
	}

	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}

function AttachToPawn(Pawn P)
{
	if(ModifiedWeapon != None)
	{
		ModifiedWeapon.AttachToPawn(P);
		ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}
}

function DetachFromPawn(Pawn P)
{
	StopEffect();
	
	if(ModifiedWeapon != None)
		ModifiedWeapon.DetachFromPawn(P);
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	if(ModifiedWeapon != None)
	{
		ModifiedWeapon.BringUp(PrevWeapon);
		if (ModifiedWeapon.TimerRate > 0)
		{
			SetTimer(ModifiedWeapon.TimerRate, false);
			ModifiedWeapon.SetTimer(0, false);
		}
		ClientState = ModifiedWeapon.ClientState;

		//Set new weapon speed
		SetWeaponSpeed();
		
		StartEffect();
	}
}

simulated function bool PutDown()
{
	local bool bResult;

	bResult = ModifiedWeapon.PutDown();
	if (ModifiedWeapon.TimerRate > 0)
	{
		SetTimer(ModifiedWeapon.TimerRate, false);
		ModifiedWeapon.SetTimer(0, false);
	}
	ClientState = ModifiedWeapon.ClientState;

	return bResult;
}

/*
	Interface for pawn property affecting weapon magics (like Quickfoot).
	This is used by the magic maker artifacts to properly disable / enable magic effects.
*/
function StartEffect();
function StopEffect();

/*
	Called by RPGEffect when it is about to be applied.
	Returns whether or not this effect can be applied when this weapon is being held.
*/
function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier)
{
	return true;
}

simulated function SetOverlayMaterial(Material mat, float time, bool bOverride)
{
	if (ModifierOverlay != None && bIdentified && mat != ModifierOverlay && time > 0)
	{
		ModifiedWeapon.SetOverlayMaterial(mat, time, true);
		if (WeaponAttachment(ThirdPersonActor) != None)
			ThirdPersonActor.SetOverlayMaterial(mat, time, true);
	}
	else if (ModifierOverlay == None || !bIdentified || time > 0)
		ModifiedWeapon.SetOverlayMaterial(mat, time, bOverride);
	else
	{
		if (time < 0)
			bOverride = true;
		ModifiedWeapon.SetOverlayMaterial(ModifierOverlay, 1000000, bOverride);
		if (WeaponAttachment(ThirdPersonActor) != None)
			ThirdPersonActor.SetOverlayMaterial(ModifierOverlay, 1000000, bOverride);
	}
}

function DropFrom(vector StartLocation)
{
    local int m;
    local Pickup Pickup;
    local Inventory Inv;
    local RPGWeapon W;
	local RPGPlayerReplicationInfo RPRI;
    local RPGPlayerReplicationInfo.OldRPGWeaponInfo MyInfo;
    local bool bFoundAnother;

    if (!bCanThrow)
    {
    	// hack for default weapons so Controller.GetLastWeapon() will return the modified weapon's class
    	if (Instigator.Health <= 0)
    		Destroy();
        return;
    }
    if (!HasAmmo())
    {
    	return;
    }

    ClientWeaponThrown();

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m].bIsFiring)
            StopFire(m);
    }

	Pickup = Spawn(PickupClass,,, StartLocation);
	if ( Pickup != None )
	{
		Pickup.InitDroppedPickupFor(self);
		Pickup.Velocity = Velocity;
		References++;
        	if (Instigator.Health > 0)
        	{
			WeaponPickup(Pickup).bThrown = true;

			//only toss 1 ammo if have another weapon of the same class
			for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				W = RPGWeapon(Inv);
				if (W != None && W != self && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
				{
					bFoundAnother = true;
					if (W.bNoAmmoInstances)
					{
						if (AmmoClass[0] != None)
							W.ModifiedWeapon.AmmoCharge[0] -= 1;
						if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
							W.ModifiedWeapon.AmmoCharge[1] -= 1;
					}
				}
			}
			if (bFoundAnother)
			{
				if (AmmoClass[0] != None)
				{
					WeaponPickup(Pickup).AmmoAmount[0] = 1;
					if (!bNoAmmoInstances)
						Ammo[0].AmmoAmount -= 1;
				}
				if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
				{
					WeaponPickup(Pickup).AmmoAmount[1] = 1;
					if (!bNoAmmoInstances)
						Ammo[1].AmmoAmount -= 1;
				}
				if (!bNoAmmoInstances)
				{
					Ammo[0] = None;
					Ammo[1] = None;
					ModifiedWeapon.Ammo[0] = None;
					ModifiedWeapon.Ammo[1] = None;
				}
			}
		}
	}

    SetTimer(0, false);
    if (Instigator != None)
    {
		if (ModifiedWeapon != None)
		{
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		}
		
		DetachFromPawn(Instigator);
		Instigator.DeleteInventory(self);
    }
    if (RPRI != None)
    {
        MyInfo.ModifiedClass = ModifiedWeapon.Class;
        MyInfo.Weapon = self;
		
		if(bAddToOldWeapons)
		{
			RPRI.OldRPGWeapons[RPRI.OldRPGWeapons.length] = MyInfo;
			References++;
		}
		
		DestroyModifiedWeapon();
    }
    else if (Pickup == None)
	{
    	Destroy();
	}
}

simulated function ClientWeaponThrown()
{
	Super.ClientWeaponThrown();

	if(Level.NetMode == NM_Client)
		DestroyModifiedWeapon();
}

function bool AddAmmo(int AmmoToAdd, int Mode)
{
	if (bNoAmmoInstances)
	{
		if (AmmoClass[0] == AmmoClass[mode])
			mode = 0;
		if (Level.GRI.WeaponBerserk > 1.0)
			ModifiedWeapon.AmmoCharge[mode] = MaxAmmo(Mode);
		else if (ModifiedWeapon.AmmoCharge[mode] < MaxAmmo(mode))
			ModifiedWeapon.AmmoCharge[mode] = Min(MaxAmmo(mode), ModifiedWeapon.AmmoCharge[mode]+AmmoToAdd);
		ModifiedWeapon.NetUpdateTime = Level.TimeSeconds - 1;
		SyncUpAmmoCharges();
		return true;
	}

	if (Ammo[Mode] != None)
		return Ammo[Mode].AddAmmo(AmmoToAdd);

	return false;
}

simulated function MaxOutAmmo()
{
	if (bNoAmmoInstances)
	{
		if (AmmoClass[0] != None)
			ModifiedWeapon.AmmoCharge[0] = MaxAmmo(0);
		if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
			ModifiedWeapon.AmmoCharge[1] = MaxAmmo(1);
		SyncUpAmmoCharges();
		return;
	}
	if (Ammo[0] != None)
		Ammo[0].AmmoAmount = Ammo[0].MaxAmmo;
	if (Ammo[1] != None)
		Ammo[1].AmmoAmount = Ammo[1].MaxAmmo;
}

simulated function SuperMaxOutAmmo()
{
	ModifiedWeapon.SuperMaxOutAmmo();
}

simulated function int MaxAmmo(int mode)
{
	if(HolderRPRI == None)
		SetHolderRPRI();

	return ModifiedWeapon.MaxAmmo(mode) * (1.0 + 0.01 * HolderRPRI.AmmoMax);
}

simulated function FillToInitialAmmo()
{
	if(!class'MutTitanRPG'.static.Instance(Level).IsSuperWeaponAmmo(AmmoClass[0]))
	{
		ModifiedWeapon.FillToInitialAmmo();

		if(bNoAmmoInstances)
		{
			if(AmmoClass[0] != None)
				ModifiedWeapon.AmmoCharge[0] = Max(ModifiedWeapon.AmmoCharge[0], AmmoClass[0].Default.InitialAmount * (1.0 + 0.01 * HolderRPRI.AmmoMax));
				
			if(AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
				ModifiedWeapon.AmmoCharge[1] = Max(ModifiedWeapon.AmmoCharge[1], AmmoClass[1].Default.InitialAmount * (1.0 + 0.01 * HolderRPRI.AmmoMax));
			
			SyncUpAmmoCharges();
		}
		else
		{
			if(Ammo[0] != None)
				Ammo[0].AmmoAmount = Max(Ammo[0].AmmoAmount,Ammo[0].default.InitialAmount * (1.0 + 0.01 * HolderRPRI.AmmoMax));
				
			if(Ammo[1] != None)
				Ammo[1].AmmoAmount = Max(Ammo[1].AmmoAmount,Ammo[1].default.InitialAmount * (1.0 + 0.01 * HolderRPRI.AmmoMax));
		}
	}
	else if(class'MutTitanRPG'.static.Instance(Level).bAllowSuperWeaponReplenish)
	{
		ModifiedWeapon.FillToInitialAmmo();
		if(bNoAmmoInstances)
		{
			SyncUpAmmoCharges();
		}
	}
}

simulated function int AmmoAmount(int mode)
{
	if(ModifiedWeapon != None)
		return ModifiedWeapon.AmmoAmount(mode);
	else
		return 0;
}

simulated function bool AmmoMaxed(int mode)
{
	if(ModifiedWeapon != None)
		return ModifiedWeapon.AmmoMaxed(mode);
	else
		return false;
}

simulated function bool NeedAmmo(int mode)
{
	if (bNoAmmoInstances)
	{
		if (AmmoClass[0] == AmmoClass[mode])
			mode = 0;
		if (AmmoClass[mode] == None)
			return false;

		return (ModifiedWeapon.AmmoCharge[Mode] < AmmoClass[mode].default.InitialAmount * (1.0 + 0.01 * HolderRPRI.AmmoMax));
	}
	if (Ammo[mode] != None)
		 return (Ammo[mode].AmmoAmount < Ammo[mode].InitialAmount * (1.0 + 0.01 * HolderRPRI.AmmoMax));

	return false;
}

simulated function CheckOutOfAmmo()
{
	if (Instigator != None && Instigator.Weapon == self && ModifiedWeapon != None)
	{
		if (bNoAmmoInstances)
		{
			if (ModifiedWeapon.AmmoCharge[0] <= 0 && ModifiedWeapon.AmmoCharge[1] <= 0)
				OutOfAmmo();
			return;
		}

		if (Ammo[0] != None)
			Ammo[0].CheckOutOfAmmo();
		if (Ammo[1] != None)
			Ammo[1].CheckOutOfAmmo();
	}
}

function class<DamageType> GetDamageType()
{
	return ModifiedWeapon.GetDamageType();
}

simulated function bool WantsZoomFade()
{
	return ModifiedWeapon.WantsZoomFade();
}

function bool CanHeal(Actor Other)
{
	return ModifiedWeapon.CanHeal(Other);
}

function bool ShouldFireWithoutTarget()
{
	return ModifiedWeapon.ShouldFireWithoutTarget();
}

simulated function PawnUnpossessed()
{
	ModifiedWeapon.PawnUnpossessed();
}

//I'm sure I don't need to explain the magnitude of this awful hack
exec function ChangeAmmo()
{
	if (PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("ChangeAmmo");
		Instigator.Weapon = self;
		FireMode[0] = ModifiedWeapon.FireMode[0];
		FireMode[1] = ModifiedWeapon.FireMode[1];
		Ammo[0] = ModifiedWeapon.Ammo[0];
		Ammo[1] = ModifiedWeapon.Ammo[1];
		AmmoClass[0] = ModifiedWeapon.AmmoClass[0];
		AmmoClass[1] = ModifiedWeapon.AmmoClass[1];
		ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}
}

//the next two are for Remote Strike
//why someone would want to play a realism mod with magic weapons is beyond me
exec function ReloadMeNow()
{
	if (PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("ReloadMeNow");
		Instigator.Weapon = self;
	}
}

exec function FinishReloading()
{
	if (PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("FinishReloading");
		Instigator.Weapon = self;
	}
}

function ServerForceUpdate()
{
	NetUpdateTime = Level.TimeSeconds - 1;
}

state PendingClientWeaponSet
{
    simulated function EndState()
    {
	if (Instigator != None && PlayerController(Instigator.Controller) != None)
	{
		if (bIdentified)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'LocalMessage_Identify', 1,,, self);
		else if (ModifiedWeapon.PickupClass != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(ModifiedWeapon.PickupClass.default.MessageClass, 0,,,ModifiedWeapon.PickupClass);
	}
    }
}

defaultproperties
{
	PatternPos="$W"
	PatternNeg="$W"
	PickupClass=Class'RPGWeaponPickup'
	bGameRelevant=True
	BerserkFireRateScale=1.333333
	bAddToOldWeapons=True;
	DamageBonus=0.000000
	DamageBonusText="$1 damage"
}
