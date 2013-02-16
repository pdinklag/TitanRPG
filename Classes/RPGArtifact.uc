class RPGArtifact extends Powerups
	config(TitanRPG)
	abstract
    HideDropDown;

var config int CostPerSec; //default adrenaline cost per second
var config float MinActivationTime; //zero means single hit usage (e.g. Repulsion)
var config int MinAdrenaline; //adrenaline required to activate this artifact

var config Color HudColor;

var config float Cooldown;
var config bool bChargeUp; //initial "cooldown"
var config bool bResetCooldownOnRespawn;

var float CurrentCostPerSec;
var config float FlagMultiplier; //scale the cost per sec when holding the flag

var config bool bAllowInVehicle;
var string ArtifactID; //for GetArtifact / RPGGetArtifact
var float ActivatedTime;
var config bool bCanBeTossed;

var config bool bExclusive; //if true, cannot be activated if another Artifact with bExclusive is already active

var Sound CantUseSound; //played when CanActivate() fails

//Ammo
var config int MaxUses; //num uses left
var int NumUses;

var bool bHeld; //true if this artifact was ever held by anybody (used for initial charge-up)

//Selection menu
var bool bSelection, bInSelection;
var int SelectedOption;

var localized string Description;

const MSG_Adrenaline = 0x0000;
const MSG_Cooldown = 0x0001;
const MSG_Expired = 0x0002;
const MSG_NotInVehicle = 0x0003;
const MSG_Exclusive = 0x0004;

var localized string
	MSG_Text_Adrenaline,
	MSG_Text_Cooldown,
	MSG_Text_Expired,
	MSG_Text_NotInVehicle,
	MSG_Text_Exclusive;

//these are for the HUD
var float NextUseTime; //time when this artifact will be available again

//RPRI of current holder
var RPGPlayerReplicationInfo InstigatorRPRI;

replication
{
	reliable if(Role == ROLE_Authority && bNetDirty && MaxUses > 0)
		NumUses;

	reliable if(Role < ROLE_Authority)
		TossArtifact, ServerSelectOption, ServerCloseSelection;
	
	reliable if(Role == ROLE_Authority)
		ClientNotifyCooldown, Msg;
}

static function array<RPGArtifact> GetActiveArtifacts(Pawn Other) {
    local Inventory Inv;
    local array<RPGArtifact> List;
    
	for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(RPGArtifact(Inv) != None && RPGArtifact(Inv).bActive)
			List[List.Length] = RPGArtifact(Inv);
	}
    return List;
}

static function bool HasActiveArtifact(Pawn Other)
{
	local Inventory Inv;
	
	for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(RPGArtifact(Inv) != None && RPGArtifact(Inv).bActive)
			return true;
	}
	return false;
}

static function RPGArtifact HasArtifact(Pawn Other)
{
	return RPGArtifact(Other.FindInventoryType(default.class));
}

static function bool IsActiveFor(Pawn Other)
{
	local Inventory Inv;

	if(Other == None)
		return false;
	
	for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(Inv.class == default.class && RPGArtifact(Inv).bActive)
			return true;
	}
	return false;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	NumUses = MaxUses;
}

function StripOut()
{
	local Inventory Inv;

	//Remove me.
	for(Inv = Instigator.Inventory; Inv != None && Inv.Inventory != Self; Inv = Inv.Inventory);
	
	if(Inv != None)
		Inv.Inventory = Self.Inventory;
	else
		Instigator.Inventory = Self.Inventory;
	
	Self.Inventory = None;
}

function SortIn()
{
	local bool bAdded;
	local Inventory Inv, Prev;
	local int OrderEntry, i;

	if(InstigatorRPRI != None)
	{
		//Re-add me.
		if(Instigator.Inventory != None)
		{
			//Sort the new artifact in so the artifact order is correct.
			OrderEntry = InstigatorRPRI.FindOrderEntry(default.class);
			if(OrderEntry >= 0)
			{
				for(Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
				{
					if(Inv.IsA('RPGArtifact'))
					{
						i = InstigatorRPRI.FindOrderEntry(class<RPGArtifact>(Inv.class));
						if(i == -1 || i > OrderEntry)
						{
							Self.Inventory = Inv;
                            Self.NetUpdateTime = Level.TimeSeconds - 1;
                            
							if(Prev != None) {
								Prev.Inventory = Self;
                                Prev.NetUpdateTime = Level.TimeSeconds - 1;
							} else {
								Instigator.Inventory = Self;
                                Instigator.NetUpdateTime = Level.TimeSeconds - 1;
                            }
							
							bAdded = true;
							break;
						}
					}
					Prev = Inv;
				}
			}
		}
	}

	if(!bAdded)
	{
		//Add to end instead
		for(Inv = Instigator.Inventory; Inv != None && Inv.Inventory != None; Inv = Inv.Inventory);

		if(Inv != None) {
			Inv.Inventory = Self;
            Inv.NetUpdateTime = Level.TimeSeconds - 1;
		} else {
			Instigator.Inventory = Self;
            Instigator.NetUpdateTime = Level.TimeSeconds - 1;
        }
	}
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super.GiveTo(Other, Pickup);
	
	InstigatorRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
	
	StripOut();
	SortIn();
	
	if(InstigatorRPRI != None)
		InstigatorRPRI.ModifyArtifact(Self);
        
    if(bChargeUp && !bHeld) {
        DoCooldown();
    }
    
    bHeld = True;

	if(Level.TimeSeconds < NextUseTime) {
		ClientNotifyCooldown(NextUseTime - Level.TimeSeconds);
	}
	
	GotoState('');
}

//New interface to allow damage scaling for artifacts -pd
function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType);
function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType);

/*
	Called by RPGEffect when it is about to be applied.
	Returns whether or not this effect can be applied when this ability is being owned.
*/
function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier)
{
	return true;
}

function bool HandlePickupQuery(Pickup Item)
{
	if(Item.InventoryType == class)
	{
		if (bCanHaveMultipleCopies)
		{
			NumCopies++;
		}
		else if ( bDisplayableInv )
		{
			if (Item.Inventory != None)
				Charge = Max(Charge, Item.Inventory.Charge);
			else
				Charge = Max(Charge, Item.InventoryType.Default.Charge);
		}
		else
		{
			return false;
		}

		Item.AnnouncePickup(Pawn(Owner));
		Item.SetRespawn();
		return true;
	}
	
	if(Inventory == None)
	{
		return false;
	}

	return Inventory.HandlePickupQuery(Item);
}

//Toss out this artifact
exec function TossArtifact()
{
	local vector X, Y, Z;

	if(bCanBeTossed)
	{
		Instigator.NextItem();
		Velocity = Vector(Instigator.Controller.GetViewRotation());
		Velocity = Velocity * ((Instigator.Velocity Dot Velocity) + 500) + Vect(0,0,200);
		GetAxes(Instigator.Rotation, X, Y, Z);
		DropFrom(Instigator.Location + 0.8 * Instigator.CollisionRadius * X - 0.5 * Instigator.CollisionRadius * Y);
	}
}

function DropFrom(vector StartLocation)
{
	if(Instigator != None && Instigator.Controller.IsA('PlayerController'))
		CloseSelection();

	if(bActive)
		GotoState('');

	bActive = false;

	if(!bResetCooldownOnRespawn && InstigatorRPRI != None)
		InstigatorRPRI.SaveCooldown(Self);

	if(bCanBeTossed)
	{
		Super.DropFrom(StartLocation);
	}
	else
	{
		Destroy();
		Instigator.NextItem();
	}
	
	InstigatorRPRI = None;
}

function UsedUp()
{
	if(Pawn(Owner) != None)
	{
		Activate();
		Msg(MSG_Expired);
	}
}

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_Adrenaline:
			return Repl(default.MSG_Text_Adrenaline, "$1", string(Value));
		
		case MSG_Cooldown:
			return Repl(default.MSG_Text_Cooldown, "$1", string(Value) @ class'MutTitanRPG'.static.GetSecondsText(Value));
			
		case MSG_Expired:
			return default.MSG_Text_Expired;
			
		case MSG_NotInVehicle:
			return default.MSG_Text_NotInVehicle;
		
		case MSG_Exclusive:
			return default.MSG_Text_Exclusive;
		
		default:
			return "";
	}
}

simulated function Msg(int Msg, optional int Value, optional Object Obj)
{
	if(Level.NetMode != NM_DedicatedServer && PlayerController(Instigator.Controller) != None)
		PlayerController(Instigator.Controller).ClientMessage(GetMessageString(Msg, Value, Obj));
}

function bool CanActivate()
{
	local Inventory Inv;
	local RPGArtifact A;
	local int Countdown;

	if(bExclusive)
	{
		for(Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			A = RPGArtifact(Inv);
			if(A != None && A.bExclusive && A.bActive)
			{
				Msg(MSG_Exclusive);
				return false;
			}
		}
	}

	if(Vehicle(Instigator) != None && !bAllowInVehicle)
	{
		Msg(MSG_NotInVehicle);
		return false;
	}
	
	if(Level.TimeSeconds < NextUseTime)
	{
		Countdown = int(NextUseTime - Level.TimeSeconds + 1);
		Msg(MSG_Cooldown, Countdown);
		return false;
	}

	if(MinAdrenaline == 0 && MinActivationTime > 0.0f && Instigator.Controller.Adrenaline < CostPerSec * MinActivationTime)
	{
		Msg(MSG_Adrenaline, int(CostPerSec * MinActivationTime));
		return false;
	}
	else if(Instigator.Controller.Adrenaline < Max(CostPerSec, MinAdrenaline))
	{
		Msg(MSG_Adrenaline, Max(CostPerSec, MinAdrenaline));
		return false;
	}
	
	return true;
}

function bool CanDeactivate()
{
	if(MinActivationTime > 0.0f && Level.TimeSeconds < ActivatedTime + MinActivationTime)
		return false;

	return true;
}

function DoCooldown()
{
	if(Cooldown > 0)
	{
		NextUseTime = Level.TimeSeconds + Cooldown;
		ClientNotifyCooldown(Cooldown);
	}
}

function DoAmmo()
{
	if(NumUses > 0)
	{
		NumUses--;
		if(NumUses <= 0)
			Destroy(); //used up
	}
}

function ForceCooldown(float Time)
{
	NextUseTime = Level.TimeSeconds + Time;
	ClientNotifyCooldown(Time);
}

function bool CheckSelection()
{
	local int x;

	if(bSelection && SelectedOption < 0 && GetNumOptions() > 0)
	{
		if(Instigator.Controller.IsA('PlayerController'))
		{
            if(GetNumOptions() > 1) {
                ShowSelection();
            } else {
                ServerSelectOption(0);
            }
		}
		else
		{
			x = SelectBestOption();
			if(x >= 0)
				ServerSelectOption(x);
		}
		return false;
	}
	return true;
}

function Activate() //do NOT override, use CanActivate, CanDeactivate or BeginState of state Activated instead
{
	if(bInSelection)
	{
		CloseSelection();
	}
	else if(MinActivationTime > 0.f)
	{
		if(bActive && CanDeactivate())
		{
            Instigator.PlaySound(DeactivateSound, SLOT_Interact, 1.0, true, 768);
			GotoState('');
		}
		else if(!bActive)
		{
			if(CanActivate())
			{
				if(CheckSelection())
				{
					CurrentCostPerSec = 0.f;
					Instigator.PlaySound(ActivateSound, SLOT_Interact, 1.0, true, 768);
					//Instigator.PlaySound(ActivateSound, SLOT_Interface);
					GotoState('Activated');
				}
			}
			else
			{
				SelectedOption = -1;
				if(Instigator.Controller.IsA('PlayerController'))
					PlayerController(Instigator.Controller).ClientPlaySound(CantUseSound,,, SLOT_Interface);
			}
		}
	}
	else if(CanActivate())
	{
		if(CheckSelection())
		{
			Instigator.PlaySound(ActivateSound, SLOT_Interact, 1.0, true, 768);
			
			if(DoEffect())
			{
				if(CostPerSec > 0)
					Instigator.Controller.Adrenaline = FMax(0, Instigator.Controller.Adrenaline - CostPerSec);
			
				DoAmmo();
				DoCooldown();
			}
			SelectedOption = -1;
		}
	}
	else
	{
		SelectedOption = -1;
		if(Instigator.Controller.IsA('PlayerController'))
			PlayerController(Instigator.Controller).ClientPlaySound(CantUseSound,,, SLOT_Interface);
	}
}

//interface for single-hit artifacts
function bool DoEffect()
{
	return true; //return success
}

state Activated
{
	function BeginState()
	{
		ActivatedTime = Level.TimeSeconds;
		bActive = true;
	}
	
	function EndState()
	{
		RoundAdrenaline();
		bActive = false;
		SelectedOption = -1;
		
		DoAmmo();
		DoCooldown();
	}

	event Tick(float dt)
	{
		if(Instigator == None || Instigator.Controller == None)
		{
			if(bActive)
			{
				GotoState('');
				bActive = false;
			}
		}
		else
		{
			if(CostPerSec > 0)
			{
				CurrentCostPerSec += float(CostPerSec);
				
				if(Instigator.PlayerReplicationInfo.HasFlag != None)
					CurrentCostPerSec *= FlagMultiplier;
			
				Instigator.Controller.Adrenaline -= dt * CurrentCostPerSec;
				if(Instigator.Controller.Adrenaline <= 0.0)
				{
					Instigator.Controller.Adrenaline = 0.0;
					UsedUp();
				}	
			}
			CurrentCostPerSec = 0.f; //reset
		}
	}
}

//New interface to get extra information which is displayed below the weapon's name -pd
static function string GetArtifactNameExtra()
{
	return default.Description;
}

simulated function ClientNotifyCooldown(float Delay)
{
	NextUseTime = Level.TimeSeconds + Delay;
}

simulated event Destroyed()
{
	if(Role == ROLE_Authority)
	{
		if(Instigator != None && Instigator.SelectedItem == Self)
			Instigator.NextItem();
		
		if(Instigator != None && Instigator.Controller.IsA('PlayerController'))
			CloseSelection();
	}

	Super.Destroyed();
}

//AI
//Utility function for bots
function int CountNearbyEnemies(float Radius, optional bool bSameTeam)
{
	local Pawn P;
	local int n;

	foreach Instigator.VisibleCollidingActors(class'Pawn', P, Radius)
	{
		if(
			P.Controller != None &&
			//P.Controller.bIsPlayer &&
			P.Controller.SameTeamAs(Instigator.Controller) == bSameTeam
		)
		{
			n++;
		}
	}
	return n;
}

//selection menu functions
function int SelectBestOption() //for AI use
{
	return -1; //invalid default choice
}

//abstract, called when something was picked
function OnSelection(int i);

//tell server this was selected
final function ServerSelectOption(int i)
{
	SelectedOption = i;
	bInSelection = false;
	
	if(i >= 0)
	{
		OnSelection(i);
		Activate();
	}
}

//display selection options
function ShowSelection()
{
	bInSelection = true;
	InstigatorRPRI.ClientShowSelection(Self);
}

//return selection options
simulated function string GetSelectionTitle(); //title line of selection
simulated function int GetNumOptions(); //amount of selection options
simulated function string GetOption(int i); //get text to display for option i
simulated function int GetOptionCost(int i); //get the adrenaline cost of option i

//close the selection
function CloseSelection()
{
	InstigatorRPRI.ClientCloseSelection();
	bInSelection = false;
}

//selection was closed client-side
function ServerCloseSelection()
{
	bInSelection = false;
}

//called after FightEnemy
function BotFightEnemy(Bot Bot);

//called after LoseEnemy returned true (enemy is lost)
function BotLoseEnemy(Bot Bot);

//called OFTEN
function BotWhatNext(Bot Bot);

//called by rpg avril rocket, for Decoy artifact
function BotIncomingMissile(Bot Bot, Projectile P);

//prevent rounding issues
function RoundAdrenaline()
{
	if(Instigator != None && Instigator.Controller != None)
		Instigator.Controller.Adrenaline = float(int(Instigator.Controller.Adrenaline + 0.01));
}

defaultproperties
{
	Description=""
	bCanBeTossed=True
	bCanHaveMultipleCopies=False
	bActivatable=True
	bDisplayableInv=True
	bReplicateInstigator=True
	MessageClass=Class'UnrealGame.StringMessagePlus'
	CostPerSec=0
	Cooldown=0
	SelectedOption=-1
	bChargeUp=False
	bResetCooldownOnRespawn=True
	bExclusive=False
	HudColor=(B=0,G=255,R=255,A=255)
	FlagMultiplier=1.000000
	MinActivationTime=0
	bAllowInVehicle=True
	MSG_Text_Adrenaline="$1 adrenaline is required to activate this artifact."
	MSG_Text_Cooldown="This artifact will be available in $1."
	MSG_Text_Expired="You have run out of adrenaline."
	MSG_Text_NotInVehicle="You cannot use this artifact in a vehicle."
	MSG_Text_Exclusive="You already have another exclusive artifact activated."
	CantUseSound=Sound'TitanRPG.Interface.CantUse'
}
