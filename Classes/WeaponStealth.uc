class WeaponStealth extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float StealthDelay;
var config float WalkedDistanceMax;
var config float WalkedDistanceResetPerSecond;
var config float FireSetbackAmount;

var config float StealthDamageMultiplier;

var bool bStill;
var float StillTime;

var bool bStealthed;
var vector LastLocation;
var float WalkedDistance;

var int LastPrimaryAmmo; //amount of primary ammo last tick

//HUD
var float BarPct;

var Sound StealthSound;

var localized string StealthText;
var localized string StealthBonusText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		StealthDelay, WalkedDistanceMax, WalkedDistanceResetPerSecond;

	reliable if(bNetOwner && Role == ROLE_Authority && bNetDirty)
		bStill, bStealthed, WalkedDistance;
	
	reliable if(Role == ROLE_Authority)
		ClientNotifyStill, ClientStealthBonusMessage;
}

simulated function ClientStealthBonusMessage(float Bonus)
{
	if(Level.NetMode != NM_DedicatedServer && PlayerController(Instigator.Controller) != None)
		PlayerController(Instigator.Controller).ClientMessage(Repl(StealthBonusText, "$1", Bonus));
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	
	if(bStealthed)
	{
		Damage = int(float(Damage) * StealthDamageMultiplier);
		ClientStealthBonusMessage(StealthDamageMultiplier);
	}
}

simulated function bool IsFiring()
{
	local int i;
	
	for(i = 0; i < NUM_FIRE_MODES; i++)
	{
		if(ModifiedWeapon.FireMode[i].bIsFiring)
			return true;
	}
	
	return false;
}

simulated function ClientNotifyStill()
{
	StillTime = Level.TimeSeconds;
	bStill = true;
}

simulated function WeaponTick(float dt)
{
	local int PrimaryAmmo;

	Super.WeaponTick(dt);
	
	if(xPawn(Instigator) == None)
		return;
	
	if(Role == ROLE_Authority)
	{
		if(ModifiedWeapon.bNoAmmoInstances)
			PrimaryAmmo = ModifiedWeapon.AmmoCharge[0];
		else
			PrimaryAmmo = ModifiedWeapon.Ammo[0].AmmoAmount;

		if(PrimaryAmmo < LastPrimaryAmmo)
		{
			//This is the only way I can come up with to find out whether this weapon just fired. ~pd
			if(bStealthed)
				WalkedDistance += FireSetbackAmount;
			else
				Reset();
		}
		LastPrimaryAmmo = PrimaryAmmo;
	
		if(!bStealthed)
		{
			if(
				Instigator.bIsCrouched &&
				VSize(Instigator.Velocity) == 0.f &&
				Instigator.PlayerReplicationInfo.HasFlag == None &&
				!IsFiring())
			{
				Identify();
			
				if(bStill)
				{
					if(Level.TimeSeconds - StillTime >= StealthDelay)
					{
						if(!xPawn(Instigator).bInvis)
						{
							PlaySound(StealthSound, SLOT_Interact,,,,,false);
							xPawn(Instigator).SetInvisibility(9999.f);
							
							LastLocation = Instigator.Location;
							WalkedDistance = 0.f;
							
							bStealthed = true;
						}
					}
				}
				else
				{
					bStill = true;
					StillTime = Level.TimeSeconds;
					ClientNotifyStill();
				}
			}
			else
			{
				bStill = false;
				StillTime = 0.f;
			}
		}
		else
		{
			if(
				Instigator.bIsCrouched &&
				Instigator.PlayerReplicationInfo.HasFlag == None &&
				WalkedDistance < WalkedDistanceMax)
			{
				if(VSize(Instigator.Velocity) == 0.f)
				{
					WalkedDistance = FMax(0.f, WalkedDistance - WalkedDistanceResetPerSecond * dt);
				}
				else
				{
					WalkedDistance += VSize(Instigator.Location - LastLocation);
					LastLocation = Instigator.Location;
				}
			}
			else
			{
				Reset();
			}
		}
	}
	
	if(Role < ROLE_Authority || Level.NetMode == NM_Standalone)
	{
		//Client-side simulation
		if(bStill && !bStealthed)
		{
			BarPct = (Level.TimeSeconds - StillTime) / StealthDelay;
		}
		else if(bStealthed)
		{
			BarPct = 1.f - (WalkedDistance / WalkedDistanceMax);
			
			if(VSize(Instigator.Velocity) == 0.f)
			{
				WalkedDistance = FMax(0.f, WalkedDistance - WalkedDistanceResetPerSecond * dt);
			}
			else
			{
				WalkedDistance += VSize(Instigator.Location - LastLocation);
				LastLocation = Instigator.Location;
			}
		}	
	}
}

static function string ConstructItemName(int Modifier, class<Weapon> WeaponClass)
{
	return repl(default.PatternPos, "$W", WeaponClass.default.ItemName);
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= repl(StealthText, "$1", class'Util'.static.FormatFloat(StealthDelay));
	return text;
}

simulated function float ChargeBar()
{
	if(!bStill && !bStealthed)
		return 0.0f;
	else
		return BarPct;
}

function Reset()
{
	if(xPawn(Instigator) != None && xPawn(Instigator).bInvis)
	{
		xPawn(Instigator).SetInvisibility(0.f);
		SetOverlayMaterial(ModifierOverlay, -1, true); //refresh overlay
	}
	
	bStealthed = false;
	bStill = false;
	StillTime = 0.f;
}

function StopEffect()
{
	Reset();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	local int i;
	local WeaponFire WF;

	for(i = 0; i < NUM_FIRE_MODES; i++)
	{
		WF = ModifiedWeapon.GetFireMode(i);
	
		WF.FireSound = None;
		WF.ReloadSound = None;
		WF.FlashEmitterClass = None;
		WF.SmokeEmitterClass = None;
	}

	Super.BringUp(PrevWeapon);
}

simulated function bool PutDown()
{
	local int i;
	local WeaponFire WF;

	if(Super.PutDown())
	{
		for(i = 0; i < NUM_FIRE_MODES; i++)
		{
			WF = ModifiedWeapon.GetFireMode(i);
		
			WF.FireSound = WF.default.FireSound;
			WF.ReloadSound = WF.default.ReloadSound;
			WF.FlashEmitterClass = WF.default.FlashEmitterClass;
			WF.SmokeEmitterClass = WF.default.SmokeEmitterClass;
		}
		return true;
	}
	else
	{
		return false;
	}
}

simulated function bool ShouldShowChargingBar()
{
	return true;
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	if(!Super.AllowedFor(Weapon, Other))
		return false;

	return ClassIsChildOf(Weapon, class'UTClassic.ClassicSniperRifle');
}

defaultproperties
{
	WalkedDistanceResetPerSecond=50.0
	WalkedDistanceMax=200.0
	FireSetbackAmount=150.0
	StealthDamageMultiplier=1.75
	StealthSound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
	
	StealthDelay=2.000000
	StealthText="silencer, stealth after crouching for $1 seconds"
	DamageBonus=0.000000
	MinModifier=1
	MaxModifier=1
	ModifierOverlay=FinalBlend'UCGeneric.Glass.glass04_FB'
	PatternPos="$W of Stealth"
	bCanThrow=True
	
	StealthBonusText="Stealth damage x$1!"
}

