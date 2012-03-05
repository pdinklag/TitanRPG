class Artifact_VehicleHack extends ArtifactBase_DelayedUse hidedropdown;

var Vehicle V;
var Material RedOverlay, BlueOverlay, GreenOverlay, GoldOverlay;

var Sound HackSound, UnlockedSound;

var config float MaxRadius, MaxRunningRadius;

const MSG_AlreadyHacking = 0x1000;
const MSG_NoVehicle = 0x1001;
const MSG_Unlocking = 0x1002;
const MSG_Unlocked = 0x1003;
const MSG_Failed = 0x1004;

var localized string AlreadyHackingText, NoVehicleText, UnlockingText, UnlockedText, FailedText;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_AlreadyHacking:
			return default.AlreadyHackingText;
			
		case MSG_NoVehicle:
			return default.NoVehicleText;
			
		case MSG_Unlocking:
			return Repl(default.UnlockingText, "$1", Vehicle(Obj).VehicleNameString);
			
		case MSG_Unlocked:
			return Repl(default.UnlockedText, "$1", Vehicle(Obj).VehicleNameString);
			
		case MSG_Failed:
			return default.FailedText;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function bool CanActivate()
{
	local float Distance, MinDistance;
	local Vehicle Found;

	if(V != None)
	{
		Msg(MSG_AlreadyHacking);
		return false;
	}

	if(!Super.CanActivate())
		return false;
	
	V = None;
	
	foreach Instigator.VisibleCollidingActors(class'Vehicle', Found, MaxRadius)
	{
		if(Found.bTeamLocked && Found.Team != Instigator.GetTeamNum() && Found.IsVehicleEmpty())
		{
			Distance = VSize(Found.Location - Instigator.Location);
			if(V == None || Distance < MinDistance)
			{
				V = Found;
				MinDistance = Distance;
			}
		}
	}
	
	if(V != None)
	{
		return true;
	}
	else
	{
		Msg(MSG_NoVehicle);
		return false;
	}
}

state Activated
{
	function BeginState()
	{
		local int Team;
	
		Super.BeginState();
		
		Msg(MSG_Unlocking,, V);
		
		Instigator.PlaySound(HackSound, SLOT_None, 1.5 * Instigator.TransientSoundVolume,,1000,1.0);

		Team = Instigator.GetTeamNum();
		switch(Team)
		{
			case 0:
				ApplySkin(V, RedOverlay);
				break;
			
			case 1:
				ApplySkin(V, BlueOverlay);
				break;
			
			//OLTeamGames support
			case 2:
				ApplySkin(V, GreenOverlay);
				break;
				
			case 3:
				ApplySkin(V, GoldOverlay);
				break;
		}
	}
	
	event Tick(float dt)
	{
		if(VSize(Instigator.Location - V.Location) > MaxRunningRadius)
		{
			Msg(MSG_Failed);
			GotoState('');
			return;
		}
	
		Super.Tick(dt);
	}

	function bool DoEffect()
	{
		V.bTeamLocked = false;
		V.PlaySound(UnlockedSound, SLOT_None, 1.5 * V.TransientSoundVolume,,1000,1.0);
		Msg(MSG_Unlocked,, V);
		return true;
	}
	
	function EndState()
	{
		if(V != None)
		{
			ApplySkin(V, None);
			V = None;
		}
		
		Super.EndState();
	}
}

static function ApplySkin(Vehicle V, Material Mat)
{
	local int x;

	if(ONSWeaponPawn(V) != None)
		class'Sync_OverlayMaterial'.static.Sync(ONSWeaponPawn(V).Gun, Mat, -1, true);
	else
		class'Sync_OverlayMaterial'.static.Sync(V, Mat, -1, true);
	
	if(ONSVehicle(V) != None)
	{
		for(x = 0; x < ONSVehicle(V).Weapons.Length; x++)
			class'Sync_OverlayMaterial'.static.Sync(ONSVehicle(V).Weapons[x], Mat, -1, true);
	
		for(x = 0; x < ONSVehicle(V).WeaponPawns.Length; x++)
			class'Sync_OverlayMaterial'.static.Sync(ONSVehicle(V).WeaponPawns[x].Gun, Mat, -1, true);
	}
}

defaultproperties
{
	AlreadyHackingText="You are already hacking a vehicle!"
	FailedText="You went away from the vehicle!"
	UnlockingText="Unlocking $1..."
	UnlockedText="$1 unlocked!"
	NoVehicleText="There is no locked vehicle near you."
	RedOverlay=Material'TitanRPG.Overlays.VHackRed'
	BlueOverlay=Material'TitanRPG.Overlays.VHackBlue'
	GreenOverlay=Material'TitanRPG.Overlays.VHackGreen'
	GoldOverlay=Material'TitanRPG.Overlays.VHackGold'
	MaxRadius=512.000000
	MaxRunningRadius=512.000000
	CostPerSec=10
	MinActivationTime=5.000000
	IconMaterial=Texture'TitanRPG.ArtifactIcons.VehicleHack'
	ItemName="Vehicle Hack"
	ArtifactID="VehicleHack"
	Description="Unlocks an enemy vehicle."
	HudColor=(B=0,G=192,R=0)
	bAllowInVehicle=False
	bCanBeTossed=False
	bChargeUp=True
	HackSound=Sound'GeneralAmbience.beep6'
	UnlockedSound=Sound'PickupSounds.MinigunAmmoPickup'
}
