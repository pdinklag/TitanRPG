class WeaponModifier_Stealth extends RPGWeaponModifier;

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

var Sound StealthSound;

var localized string StealthText;
var localized string StealthBonusText;

replication {
	reliable if(Role == ROLE_Authority)
        bStill, bStealthed, WalkedDistance;
        
    reliable if(Role == ROLE_Authority)
		ClientNotifyStill, ClientReceiveStealthConfig;
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other) {
	if(!Super.AllowedFor(Weapon, Other))
		return false;

    return ClassIsChildOf(Weapon, class'RPGClassicSniperRifle');
}

function SendConfig() {
    Super.SendConfig();
    ClientReceiveStealthConfig(StealthDelay, WalkedDistanceMax, WalkedDistanceResetPerSecond);
}

simulated function ClientReceiveStealthConfig(float a, float b, float c) {
    if(Role < ROLE_Authority) {
        StealthDelay = a;
        WalkedDistanceMax = b;
        WalkedDistanceResetPerSecond = c;
    }
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType) {
	Super.AdjustTargetDamage(Damage, OriginalDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType);
	
	if(bStealthed) {
		Damage = int(float(Damage) * StealthDamageMultiplier);
        
        if(PlayerController(InstigatedBy.Controller) != None) {
            PlayerController(InstigatedBy.Controller).ClientMessage(Repl(StealthBonusText, "$1", StealthDamageMultiplier));
        }
	}
}

simulated function ClientNotifyStill() {
	StillTime = Level.TimeSeconds;
	bStill = true;
}

function RPGTick(float dt)
{
	local int PrimaryAmmo;

	Super.RPGTick(dt);
	
	if(xPawn(Instigator) == None)
		return;
	
    PrimaryAmmo = Weapon.AmmoAmount(0);
    if(PrimaryAmmo < LastPrimaryAmmo) {
        //This is the only way I can come up with to find out whether this weapon just fired. ~pd
        if(bStealthed) {
            WalkedDistance += FireSetbackAmount;
            NetUpdateTime = Level.TimeSeconds - 1; //force net update
        } else {
            Reset();
        }
    }
    LastPrimaryAmmo = PrimaryAmmo;

    if(!bStealthed) {
        if(
            Instigator.bIsCrouched &&
            VSize(Instigator.Velocity) == 0.f &&
            Instigator.PlayerReplicationInfo.HasFlag == None &&
            !Weapon.IsFiring())
        {
            Identify();
        
            if(bStill) {
                if(Level.TimeSeconds - StillTime >= StealthDelay) {
                    if(!xPawn(Instigator).bInvis) {
                        Instigator.PlaySound(StealthSound, SLOT_Interact,,,,, false);
                        
                        xPawn(Instigator).SetInvisibility(9999.f);
                        SetOverlay(xPawn(Instigator).InvisMaterial);
                        
                        LastLocation = Instigator.Location;
                        WalkedDistance = 0.f;
                        
                        bStealthed = true;
                    }
                }
            } else {
                bStill = true;
                StillTime = Level.TimeSeconds;
                ClientNotifyStill();
            }
        } else {
            bStill = false;
            StillTime = 0.f;
        }
    } else {
        if(
            Instigator.bIsCrouched &&
            Instigator.PlayerReplicationInfo.HasFlag == None &&
            WalkedDistance < WalkedDistanceMax)
        {
            if(VSize(Instigator.Velocity) == 0.f) {
                WalkedDistance = FMax(0.f, WalkedDistance - WalkedDistanceResetPerSecond * dt);
            } else {
                WalkedDistance += VSize(Instigator.Location - LastLocation);
                LastLocation = Instigator.Location;
            }
        } else {
            Reset();
        }
    }
}

simulated function ClientRPGTick(float dt) {
    Super.ClientRPGTick(dt);

    //Client-side simulation
    if(bStill && !bStealthed) {
        SetBarCharge((Level.TimeSeconds - StillTime) / StealthDelay);
    } else if(bStealthed) {
        SetBarCharge(1.f - (WalkedDistance / WalkedDistanceMax));
        
        if(VSize(Instigator.Velocity) == 0.f)
        {
            WalkedDistance = FMax(0.f, WalkedDistance - WalkedDistanceResetPerSecond * dt);
        }
        else
        {
            WalkedDistance += VSize(Instigator.Location - LastLocation);
            LastLocation = Instigator.Location;
        }
    } else {
        SetBarCharge(0);
    }
}

simulated function SetBarCharge(float x) {
    if(RPGClassicSniperRifle(Weapon) != None) {
        RPGClassicSniperRifle(Weapon).BarCharge = x;
    } else {
        Warn("No RPGClassicSniperRifle!");
    }
}

function Reset() {
    if(xPawn(Instigator) != None && xPawn(Instigator).bInvis) {
        xPawn(Instigator).SetInvisibility(0.f);
        SetOverlay();
    }

    bStealthed = false;
    bStill = false;
    StillTime = 0.f;
}

simulated function ApplyEffect(bool b) {
    local int i;
    local WeaponFire WF;
    
    if(Weapon != None) {
        if(b) {
            Weapon.bShowChargingBar = true;
            for(i = 0; i < Weapon.NUM_FIRE_MODES; i++) {
                WF = Weapon.GetFireMode(i);

                WF.FireSound = None;
                WF.ReloadSound = None;
                WF.FlashEmitterClass = None;
                WF.SmokeEmitterClass = None;
            }
        } else {
            Weapon.bShowChargingBar = Weapon.default.bShowChargingBar;
            for(i = 0; i < Weapon.NUM_FIRE_MODES; i++) {
                WF = Weapon.GetFireMode(i);
                
                WF.FireSound = WF.default.FireSound;
                WF.ReloadSound = WF.default.ReloadSound;
                WF.FlashEmitterClass = WF.default.FlashEmitterClass;
                WF.SmokeEmitterClass = WF.default.SmokeEmitterClass;
            }
        }
    }
}

function StartEffect() {
    ApplyEffect(true);
}

function StopEffect() {
    Reset();
    ApplyEffect(false);
}

simulated function ClientStartEffect() {
    ApplyEffect(true);
}

simulated function ClientStopEffect() {
    ApplyEffect(false);
}

simulated function BuildDescription() {
    Super.BuildDescription();
    AddToDescription(Repl(StealthText, "$1", int(StealthDelay)));
}

defaultproperties {
    WalkedDistanceResetPerSecond=50.0
    WalkedDistanceMax=200.0
    FireSetbackAmount=150.0
    StealthDamageMultiplier=1.75
    StealthSound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'

    StealthDelay=2.000000
    StealthText="silencer, stealth after $1s when crouching"
    DamageBonus=0.000000
    MinModifier=1
    MaxModifier=1
    bOmitModifierInName=True
    ModifierOverlay=FinalBlend'UCGeneric.Glass.glass04_FB'
    PatternPos="$W of Stealth"

    StealthBonusText="Stealth damage x$1!"
}
