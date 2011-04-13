
/*
	FINALLY getting rid of RPGWeapon. This is the future.
*/
class RPGWeaponModifier extends ReplicationInfo abstract
	Config(TitanRPG);

//Weapon
var Weapon Weapon;
var bool bActive;

//Modifier level
var config int MinModifier, MaxModifier;
var bool bCanHaveZeroModifier;

var int Modifier;

//Bonus
var config float DamageBonus, BonusPerLevel;

//Visual
var Material ModifierOverlay;

//Item name
var localized string PatternPos, PatternNeg;
var localized string DamageBonusText;

//AI
var float AIRatingBonus;

replication
{
	reliable if(Role == ROLE_Authority && bNetOwner)
		Weapon, bActive, Modifier, DamageBonus, BonusPerLevel;
	
	reliable if(Role == ROLE_Authority)
		ClientStartEffect, ClientStopEffect, ClientConstructItemName, ClientSetOverlay;
}

static function RPGWeaponModifier GetFor(Weapon W)
{
	local RPGWeaponModifier WM;
	
	foreach W.ChildActors(class'RPGWeaponModifier', WM)
		return WM;

	return None;
}

static function string ConstructItemName(class<Weapon> WeaponClass, int Modifier)
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

function int GetRandomPositiveModifierLevel()
{
	if(MaxModifier == 0)
		return 0;
	else
		return Rand(MaxModifier) + 1;
}

function SetModifier(int x)
{
	local bool bWasActive;
	
	bWasActive = bActive;
	if(bActive)
		SetActive(false);

	Modifier = x;
	Weapon.ItemName = ConstructItemName(Weapon.class, Modifier);
	ClientConstructItemName(Weapon.class, Modifier);
	
	if(bWasActive)
		SetActive(true);
}

simulated function ClientConstructItemName(class<Weapon> SyncWeaponClass, int SyncModifier)
{
	if(Role < ROLE_Authority)
		Weapon.ItemName = ConstructItemName(SyncWeaponClass, SyncModifier);
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
		
		Instigator = Weapon.Instigator;
	}
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	
	if(Role < ROLE_Authority)
		SetOwner(Weapon);
}

simulated event Tick(float dt)
{
	if(Role == ROLE_Authority)
	{
		if(Weapon == None)
		{
			SetActive(false);
			Destroy();
			return;
		}
		
		if(Instigator != None)
		{
			if(!bActive && Instigator.Weapon == Weapon)
				SetActive(true);
			else if(bActive && Instigator.Weapon != Weapon)
				SetActive(false);
		}
		else if(bActive)
		{
			SetActive(false);
		}
		
		if(bActive)
			RPGTick(dt);
	}
}

function SetActive(bool b)
{
	bActive = b;
	if(bActive)
	{
		StartEffect();
		SetOverlay();
		ClientStartEffect();
	}
	else
	{
		StopEffect();
		SetOverlay();
		ClientStopEffect();
	}
}

simulated function SetOverlay()
{
	Weapon.SetOverlayMaterial(ModifierOverlay, 9999, true);

	if(WeaponAttachment(Weapon.ThirdPersonActor) != None)
		Weapon.ThirdPersonActor.SetOverlayMaterial(ModifierOverlay, 999, true);
	
	if(Role == ROLE_Authority)
		ClientSetOverlay();
}

simulated function ClientSetOverlay()
{
	if(Role < ROLE_Authority)
		SetOverlay();
}

//interface
function StartEffect(); //weapon gets drawn
function StopEffect(); //weapon gets put down

simulated function ClientStartEffect();
simulated function ClientStopEffect();

function RPGTick(float dt); //called only if weapon is active

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, vector HitLocation, out vector Momentum, class<DamageType> DamageType);
function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType);

function bool PreventDeath(Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	return false;
}

function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Modifier)
{
	return true;
}

function float GetAIRating()
{
	return Weapon.GetAIRating() * (1.0f + AIRatingBonus);
}

defaultproperties
{
	bCanHaveZeroModifier=True
	
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=4.00
	bAlwaysRelevant=True
	bOnlyRelevantToOwner=False
	bSkipActorPropertyReplication=True
	bOnlyDirtyReplication=True
	bReplicateMovement=False
	bReplicateInstigator=True
	bMovable=False
	bHidden=True
	
	AIRatingBonus=0
}
