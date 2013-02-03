/*
	class holding static utility functions
*/

class Util extends Object abstract;

var Color HighlightColor;

static function vector ReflectVector(vector v, vector normal)
{
	return (v - 2.0 * normal * (v dot normal));
}

static function bool InVehicle(Pawn P, Vehicle V) {
    if(P.DrivenVehicle != None) {
        if(P.DrivenVehicle == V) {
            return true;
        } else if(P.DrivenVehicle.IsA('ONSWeaponPawn') && ONSWeaponPawn(P.DrivenVehicle).VehicleBase == V) {
            return true;
        }
    }
    
    return false;
}

static function array<Pawn> GetAllPassengers(Vehicle V)
{
	local array<Pawn> Passengers;
	local int x;
	local ONSVehicle OV;
	local ONSWeaponPawn WP;
	
	if(ONSVehicle(V) != None)
		OV = ONSVehicle(V);
	else if(ONSWeaponPawn(V) != None)
		OV = ONSWeaponPawn(V).VehicleBase;
	
	if(OV != None)
	{
		if(OV.Driver != None)
			Passengers[Passengers.Length] = OV.Driver;
		
		for(x = 0; x < OV.WeaponPawns.Length; x++)
		{
			WP = OV.WeaponPawns[x];
			
			if(WP.Driver != None)
				Passengers[Passengers.Length] = WP.Driver;
		}
	}
	else
	{
		if(V.Driver != None)
			Passengers[Passengers.Length] = V.Driver;
	}
	
	return Passengers;
}

static function array<Controller> GetAllPassengerControllers(Vehicle V)
{
	local array<Controller> Passengers;
	local int x;
	local ONSVehicle OV;
	local ONSWeaponPawn WP;
	
	if(V.Controller != None)
		Passengers[Passengers.Length] = V.Controller;
	
	if(ONSVehicle(V) != None)
		OV = ONSVehicle(V);
	else if(ONSWeaponPawn(V) != None)
		OV = ONSWeaponPawn(V).VehicleBase;
	
	if(OV != None)
	{
		for(x = 0; x < OV.WeaponPawns.Length; x++)
		{
			WP = OV.WeaponPawns[x];
			
			if(WP.Controller != None)
				Passengers[Passengers.Length] = WP.Controller;
		}
	}
	
	return Passengers;
}

static function string HighlightText(string Text, Color Highlight, Color Old)
{
	return class'GameInfo'.static.MakeColorCode(Highlight) $ Text $ class'GameInfo'.static.MakeColorCode(Old);
}

static function string FormatPercent(float p)
{
	return FormatFloat(p * 100.0) $ "%";
}

static function string FormatFloat(float p)
{
	if(float(int(p)) == p)
		return string(int(p));
	else
		return string(p);
}

static function int InArray(Object x, array<Object> a)
{
	local int i;
	
	for(i = 0; i < a.Length; i++)
	{
		if(a[i] == x)
			return i;
	}
	
	return -1;
}

static function PawnScaleSpeed(Pawn P, float Multiplier)
{
	P.GroundSpeed *= Multiplier;
	P.WaterSpeed *= Multiplier;
	P.AirSpeed *= Multiplier;
}

static function Inventory GiveInventory(Pawn P, class<Inventory> InventoryClass, optional bool bRemoveIfExists)
{
	local Inventory Inv;

	if(InventoryClass == None)
		return None;
	
	Inv = P.FindInventoryType(InventoryClass);
	if(Inv != None && bRemoveIfExists)
	{
		Inv.Destroy();
		Inv = None;
	}

	if(Inv == None)
	{
		Inv = P.Spawn(InventoryClass, P);
		if( Inv != None )
		{
			Inv.GiveTo(P);
			if ( Inv != None )
				Inv.PickupFunction(P);
		}
	}
	
	return Inv;
}

static function SetWeaponFireRate(Weapon W, float Scale)
{
	local int i;
	local WeaponFire WF;
	
	if(W == None)
		return;
	
	for(i = 0; i < W.NUM_FIRE_MODES; i++)
	{
		WF = W.GetFireMode(i);
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
                
                if(RocketMultiFire(WF) != None) {
                    WF.MaxHoldTime = WF.FireRate * (RocketMultiFire(WF).MaxLoad - 1) + 0.5;
                } else {
                    WF.MaxHoldTime = WF.default.MaxHoldTime / Scale;
                }
				
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

static function AdjustWeaponFireRate(Weapon W, float Scale)
{
	local int i;
	local WeaponFire WF;
	
	if(W == None)
		return;
	
	for(i = 0; i < W.NUM_FIRE_MODES; i++)
	{
		WF = W.GetFireMode(i);
		if(WF != None)
		{
			if(MinigunFire(WF) != None)
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

                if(RocketMultiFire(WF) != None) {
                    WF.MaxHoldTime = WF.FireRate * (RocketMultiFire(WF).MaxLoad - 1) + 0.5;
                } else {
                    WF.MaxHoldTime = WF.default.MaxHoldTime / Scale;
                }
				
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

static function AdjustVehicleSpeed(Vehicle V, float Factor)
{
	local int i;

	if(ONSWheeledCraft(V) != None) //HellBender, Scorpion, Paladin, SPMA, MAS, Toilet Car, you name it
	{
		ONSWheeledCraft(V).TorqueCurve.Points[0].OutVal *= Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[1].OutVal *= Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[2].OutVal *= Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[2].InVal *= Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[3].InVal *= Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[3].OutVal *= Factor;
		
		for (i = 0; i < 5; i++)
			ONSWheeledCraft(V).GearRatios[i] *= Factor;
	}
	else if(ONSHoverCraft(V) != None) //Manta
	{
		ONSHoverCraft(V).MaxThrustForce *= Factor;
		ONSHoverCraft(V).MaxStrafeForce *= Factor;
		ONSHoverCraft(V).LatDamping *= Factor;
		ONSHoverCraft(V).LongDamping *= Factor;
		ONSHoverCraft(V).MaxRiseForce *= Factor;
	}
	else if(ONSChopperCraft(V) != None) //Raptor, Cicada
	{
		ONSChopperCraft(V).MaxThrustForce *= Factor;
		ONSChopperCraft(V).MaxStrafeForce *= Factor;
		ONSChopperCraft(V).LatDamping *= Factor;
		ONSChopperCraft(V).LongDamping *= Factor;
	}
	else if(ONSTreadCraft(V) != None) //Goliath, Ion Plasma Tank
	{
		ONSTreadCraft(V).MaxThrust *= Factor;
	}
}

static function SetVehicleSpeed(Vehicle V, float Factor)
{
	local int i;

	if(ONSWheeledCraft(V) != None) //HellBender, Scorpion, Paladin, SPMA, MAS, Toilet Car, you name it
	{
		ONSWheeledCraft(V).TorqueCurve.Points[0].OutVal = ONSWheeledCraft(V).default.TorqueCurve.Points[0].OutVal * Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[1].OutVal = ONSWheeledCraft(V).default.TorqueCurve.Points[1].OutVal * Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[2].OutVal = ONSWheeledCraft(V).default.TorqueCurve.Points[2].OutVal * Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[2].InVal = ONSWheeledCraft(V).default.TorqueCurve.Points[2].InVal * Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[3].InVal = ONSWheeledCraft(V).default.TorqueCurve.Points[3].InVal * Factor;
		ONSWheeledCraft(V).TorqueCurve.Points[3].OutVal = ONSWheeledCraft(V).default.TorqueCurve.Points[3].OutVal * Factor;
		
		for (i = 0; i < 5; i++)
			ONSWheeledCraft(V).GearRatios[i] = ONSWheeledCraft(V).Default.GearRatios[i] * Factor;
	}
	else if(ONSHoverCraft(V) != None) //Manta
	{
		ONSHoverCraft(V).MaxThrustForce = ONSHoverCraft(V).default.MaxThrustForce * Factor;
		ONSHoverCraft(V).MaxStrafeForce = ONSHoverCraft(V).default.MaxStrafeForce * Factor;
		ONSHoverCraft(V).LatDamping = ONSHoverCraft(V).default.LatDamping * Factor;
		ONSHoverCraft(V).LongDamping = ONSHoverCraft(V).default.LongDamping * Factor;
		ONSHoverCraft(V).MaxRiseForce = ONSHoverCraft(V).default.MaxRiseForce * Factor;
	}
	else if(ONSChopperCraft(V) != None) //Raptor, Cicada
	{
		ONSChopperCraft(V).MaxThrustForce = ONSChopperCraft(V).default.MaxThrustForce * Factor;
		ONSChopperCraft(V).MaxStrafeForce = ONSChopperCraft(V).default.MaxStrafeForce * Factor;
		ONSChopperCraft(V).LatDamping = ONSChopperCraft(V).default.LatDamping * Factor;
		ONSChopperCraft(V).LongDamping = ONSChopperCraft(V).default.LongDamping * Factor;
	}
	else if(ONSTreadCraft(V) != None) //Goliath, Ion Plasma Tank
	{
		ONSTreadCraft(V).MaxThrust = ONSTreadCraft(V).default.MaxThrust * Factor;
	}
}

static function SetVehicleOverlay(Vehicle V, Material Mat, float Duration, bool bOverride)
{
	local int i;
	local ONSVehicle OV;
	local ASTurret AT;

	if(ONSWeaponPawn(V) != None)
		V = ONSWeaponPawn(V).VehicleBase;
	
	OV = ONSVehicle(V);
	if(OV != None)
	{
		for(i = 0; i < OV.Weapons.Length; i++)
			class'Sync_OverlayMaterial'.static.Sync(OV.Weapons[i], Mat, Duration, bOverride);
		
		for(i = 0; i < OV.WeaponPawns.Length; i++)
			class'Sync_OverlayMaterial'.static.Sync(OV.WeaponPawns[i].Gun, Mat, Duration, bOverride);
	}
	
	AT = ASTurret(V);
	if(AT != None)
	{
		if(AT.TurretBase != None)
			class'Sync_OverlayMaterial'.static.Sync(AT.TurretBase, Mat, Duration, bOverride);

		if(AT.TurretSwivel != None)
			class'Sync_OverlayMaterial'.static.Sync(AT.TurretSwivel, Mat, Duration, bOverride);
	}
	
	class'Sync_OverlayMaterial'.static.Sync(V, Mat, Duration, bOverride);
}


//TAM support
static function IncreaseTAMWeaponFireStats(PlayerReplicationInfo PRI, string HitStatName, string Mode)
{
	local string HitStatStr;
	local Object HitStat;
	
	if(PRI == None || !PRI.IsA('Misc_PRI'))
		return;
	
	HitStatStr = PRI.GetPropertyText(HitStatName);
	HitStat = DynamicLoadObject(HitStatStr, class'Object', true);
	
	Log("HitStatStr =" @ HitStatStr @ "=>" @ HitStat, 'TitanRPG');
}

//Forces the weapon to be given to the pawn - even if he has a weapon of the same type already
static function Weapon ForceGiveTo(Pawn Other, Weapon W, optional WeaponPickup Pickup) {
    local Weapon Pivot;
    local class<Weapon> WeaponClass;
    local Actor Inv, Prev;
    
    if(W != None) {
        WeaponClass = W.class;
    } else if(Pickup != None) {
        WeaponClass = class<Weapon>(Pickup.InventoryType);
    } else {
        Warn("Insufficient parameters:" @ Other @ W @ Pickup);
    }
    
    Prev = Other;
    Inv = Other.Inventory;
    while(Inv != None) {
        if(Inv.class == WeaponClass) {
            break; //found one
        }
        
        Prev = Inv;
        Inv = Inv.Inventory;
    }
    
    if(Inv != None) {
        Pivot = Weapon(Inv);
        
        //cut of linked list (we assume that weapons are ordered and that the new weapon will be added here)
        Prev.Inventory = None;
        
        //Give weapon to pawn or spawn copy
        if(W != None) {
            W.GiveTo(Other, Pickup);
        } else {
            W = Weapon(Pickup.SpawnCopy(Other));
        }
        
        //re-add
        if(W.Inventory != None) {
            //shouldn't happen, but who knows...
            Warn("Item order changed - putting Pivot to end of list!");
            
            Prev = W;
            for(Inv = W.Inventory; Inv != None; Inv = Inv.Inventory) {
                Prev = Inv;
            }
            
            Prev.Inventory = Pivot;
        } else {
            W.Inventory = Pivot;
            W.NetUpdateTime = W.Level.TimeSeconds - 1;
        }
    } else {
        //simply give to pawn
        if(W != None) {
            W.GiveTo(Other, Pickup);
        } else {
            W = Weapon(Pickup.SpawnCopy(Other));
        }
    }
    
    return W;
}

static function SetWeaponAmmo(Weapon W, int Mode, int Ammo) {
    local int Diff;
    
    Diff = Ammo - W.AmmoAmount(Mode);
    if(Diff > 0) {
        W.AddAmmo(Diff, Mode);
    } else if(Diff < 0) {
        W.ConsumeAmmo(Mode, -Diff);
    }
}

//Grants experience for healing
static function DoHealableDamage(Pawn Healer, Pawn Healed, int Amount, optional float Factor) {
    local RPGPlayerReplicationInfo RPRI;
    local HealableDamageInv Healable;
    local int Adjusted;

    if(Healer != None && Healed != None && Amount > 0) {
        RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Healer.Controller);
        if(RPRI != None) {
            if(Factor == 0) {
                Factor = RPRI.HealingExpMultiplier;
            }
        
            Healable = HealableDamageInv(Healed.FindInventoryType(class'HealableDamageInv'));
            if(Healable != None && Healable.Damage > 0) {
                Adjusted = Min(Amount, Healable.Damage);

                if(Adjusted > 0) {	
                    Healable.Damage = Max(0, Healable.Damage - Adjusted);
                    class'RPGRules'.static.ShareExperience(RPRI, float(Adjusted) * Factor);
                }
            }
        }
    }
}

defaultproperties
{
	HighlightColor=(R=255,G=255,B=255,A=255);
}
