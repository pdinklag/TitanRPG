class VehicleMagic extends Inventory //-pd
	abstract
	config(TitanRPG);

var localized string NamePrefix, NameSuffix;
var localized string MagicName;

var config Material OverlayMat;

static function ApplyTo(Vehicle V)
{
	if(FindFor(V) != None)
		return;
		
	class'Util'.static.GiveInventory(V, default.class);
}

static function VehicleMagic FindFor(Pawn P)
{
	local Inventory Inv;
	local Vehicle V;
	
	V = Vehicle(P);
	
	if(V == None)
		return None;

	for(Inv = V.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(VehicleMagic(Inv) != None)
			return VehicleMagic(Inv);
	}
	
	return None;
}

static function VehicleMagic FindForAnyPassenger(Pawn P)
{
	local VehicleMagic VM;
	local ONSVehicle OV;
	local int i;
	
	if(Vehicle(P) == None)
		return None;
		
	VM = FindFor(P);
	if(VM != None)
		return VM;
	
	OV = ONSVehicle(P);
	if(OV != None)
	{
		for(i = 0; i < OV.WeaponPawns.length; i++)
		{
			VM = FindFor(OV.WeaponPawns[i]);
			
			if(VM != None)
				return VM;
		}
	}
	
	return None;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local VehicleMagic VM;

	if(Vehicle(Instigator) == None)
	{
		Destroy();
		return;
	}
	
	//only allow one vehicle magic at a time!
	VM = FindFor(Instigator);
	if(VM != None)
	{
		Destroy();
		return;
	}
	
	Super.GiveTo(Other, Pickup);
	
	//overlay!
	Timer();
	SetTimer(0.5, true);
	
	//Name
	Vehicle(Instigator).VehicleNameString = 
		NamePrefix $ Vehicle(Instigator).default.VehicleNameString $ NameSuffix;
		
	ModifyVehicle();
}

function Destroyed()
{
	SetTimer(0, false);

	if(Instigator != None)
	{
		Vehicle(Instigator).VehicleNameString = Vehicle(Instigator).default.VehicleNameString;
	
		UnModifyVehicle();
		DetachFromPawn(Instigator);
		Instigator.DeleteInventory(Self);
	
		SetOverlay(None, -1, true);
	}
	
	Super.Destroyed();
}

function SetOverlay(Material Mat, float time, bool bOverride)
{
	local int i;
	local ONSVehicle OV;

	if(ONSWeaponPawn(Instigator) != None && ONSWeaponPawn(Instigator).Gun != None)
	{
		//coolio, but weird -pd
		class'SyncOverlayMaterial'.static.Sync(ONSWeaponPawn(Instigator).Gun, Mat, time, bOverride);
	}
	else
	{
		OV = ONSVehicle(Instigator);
		if(OV != None)
		{
			for(i = 0; i < OV.Weapons.length; i++)
			{
				class'SyncOverlayMaterial'.static.Sync(OV.Weapons[i], Mat, time, bOverride);
			}
		}
	
		//should be used for vehicles with invisible weapon bones only,
		//but how to find out about that? :\ -pd
		class'SyncOverlayMaterial'.static.Sync(Instigator, Mat, time, bOverride);
	}
}

//Checks the vehicle's overlay material every second and updates it if possible
function Timer()
{
	if(Instigator.OverlayMaterial == None)
		SetOverlay(OverlayMat, -1, true);
}

function ModifyVehicle();
function UnModifyVehicle();
function AdjustTargetDamage(out int Damage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType);
function AdjustPlayerDamage(out int Damage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType);

defaultproperties
{
	MagicName="Unknown Magic"
	NamePrefix=""
	NameSuffix=""
}