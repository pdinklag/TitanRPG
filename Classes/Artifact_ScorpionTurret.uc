class Artifact_ScorpionTurret extends RPGArtifact;

struct ScorpionTurretStruct
{
	var class<ONSWeapon> TurretClass;
	var string DisplayName;
	var int Cost;
	var int Cooldown;
};
var config array<ScorpionTurretStruct> Turrets;

var class<ONSWeapon> SelectedType;

var ONSWeapon PendingWeapon;
var rotator OldAim; //client only

const MSG_Restriction = 0x1000;

var localized string MsgRestriction, SelectionTitle;

replication {
	reliable if(Role == ROLE_Authority && bNetDirty)
        PendingWeapon;
    
	reliable if(Role == ROLE_Authority)
		ClientPrepareWeaponSwitch, ClientReceiveTurret;
    
    unreliable if(Role < ROLE_Authority)
        ServerNotify;
}

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_Restriction:
			return default.MsgRestriction;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int i;

	Super.GiveTo(Other, Pickup);
	
	for(i = 0; i < Turrets.Length; i++) {
		ClientReceiveTurret(i, Turrets[i]);
    }
}

simulated function ClientReceiveTurret(int i, ScorpionTurretStruct T)
{
    if(Role < ROLE_Authority) {
        if(i == 0)
            Turrets.Length = 0;

        Turrets[i] = T;
    }
}

function bool CanActivate()
{
    if(ONSRV(Instigator) == None || ONSRV(Instigator).Weapons.Length <= 0) {
        Msg(MSG_Restriction);
        return false;
    }

    if(SelectedOption < 0) {
        CostPerSec = 0; //no cost until selection
    }

	if(!Super.CanActivate())
		return false;
	
	return true;
}

function bool DoEffect() {
    local ONSRV Scorp;
    local ONSWeapon OldWeapon;

    Scorp = ONSRV(Instigator);
    PendingWeapon = Scorp.Spawn(SelectedType, Scorp,, Scorp.Location, rot(0,0,0));
    
    if(PendingWeapon != None) {
        OldWeapon = Scorp.Weapons[0];
    
        Scorp.Weapons[0] = PendingWeapon;
        Scorp.AttachToBone(PendingWeapon, 'ChainGunAttachment');
        
        PendingWeapon.bActive = OldWeapon.bActive;
        PendingWeapon.Team = OldWeapon.Team;
        PendingWeapon.bForceCenterAim = OldWeapon.bForceCenterAim;
        PendingWeapon.bCallInstigatorPostRender = OldWeapon.bCallInstigatorPostRender;
        PendingWeapon.LastHitLocation = OldWeapon.LastHitLocation;
        PendingWeapon.HitCount = OldWeapon.HitCount;
        
        ClientPrepareWeaponSwitch();
        OldWeapon.Destroy();
        
        //Re-Modify vehicle (will only work server-side at this point)
        if(InstigatorRPRI != None) {
            InstigatorRPRI.DriverLeftVehicle(Scorp, Scorp.Driver);
            InstigatorRPRI.DriverEnteredVehicle(Scorp, Scorp.Driver);
        }
        
        return true;
    } else {
        return false;
    }
}

simulated function ClientPrepareWeaponSwitch() {
    local ONSRV Scorp;
    
    Scorp = ONSRV(Instigator);
    if(Role < ROLE_Authority) {
        OldAim = Scorp.Weapons[0].CurrentAim;
        Scorp.Weapons.Length = 0;
    }
}

simulated event PostNetReceive() {
    local ONSRV Scorp;
    
    Scorp = ONSRV(Instigator);
    if(Role < ROLE_Authority && Scorp != None && PendingWeapon != None && Scorp.Weapons.Length == 0) {
        Scorp.Weapons[0] = PendingWeapon;
        
        Scorp.PitchUpLimit = PendingWeapon.PitchUpLimit;
        Scorp.PitchDownLimit = PendingWeapon.PitchDownLimit;
        
        PendingWeapon.CurrentAim = OldAim;
        Scorp.bShowChargingBar = PendingWeapon.bShowChargingBar;
        
        ServerNotify();
    }
}

function ServerNotify() {
    local ONSRV Scorp;

    //Re-Modify vehicle (safe for clients now)
    Scorp = ONSRV(Instigator);
    if(Scorp != None) {
        if(InstigatorRPRI != None) {
            InstigatorRPRI.DriverLeftVehicle(Scorp, Scorp.Driver);
            InstigatorRPRI.DriverEnteredVehicle(Scorp, Scorp.Driver);
        }
        
        //Synchronize skin to all players
        class'Sync_ScorpionTurret'.static.Sync(Scorp, PendingWeapon);
    }
}

function OnSelection(int i)
{
	CostPerSec = Turrets[i].Cost;
	Cooldown = Turrets[i].Cooldown;
	SelectedType = Turrets[i].TurretClass;
}

simulated function string GetSelectionTitle()
{
	return SelectionTitle;
}

simulated function int GetNumOptions()
{
	return Turrets.Length;
}

simulated function string GetOption(int i)
{
	return Turrets[i].DisplayName;
}

simulated function int GetOptionCost(int i) {
	return Turrets[i].Cost;
}

function int SelectBestOption() {
    local Controller C;
    local int i;
    
    C = Instigator.Controller;
    if(C != None) {
        //The AI assumes that the best options are listed last
        for(i = Turrets.Length - 1; i >= 0; i--) {
            if(C.Adrenaline >= Turrets[i].Cost && FRand() < 0.5) {
                return i;
            }
        }
        
        //None
        return -1;
    } else {
        return Super.SelectBestOption();
    }
}

defaultproperties
{
	SelectionTitle="Pick a turret:"
	MsgRestriction="You can only use this artifact inside a Scorpion."

    bNetNotify=true
    
	bSelection=true

	ArtifactID="ScorpionTurret"
	Description="Switches the turret of your Scorpion."
	ItemName="Scorpion Turret"
	PickupClass=Class'ArtifactPickup_ScorpionTurret'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.ScorpTurret'
	HudColor=(B=181,G=152,R=156)
	CostPerSec=0
	Cooldown=0

	Turrets(0)=(TurretClass=class'Onslaught.ONSRVWebLauncher',DisplayName="Web Launcher",Cost=0,Cooldown=10)
}
