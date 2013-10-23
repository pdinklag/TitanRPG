class Artifact_SummonTurret extends ArtifactBase_Construct;

struct TurretTypeStruct
{
	var class<Vehicle> TurretClass;
	var int Cost;
	var int Cooldown;
};
var config array<TurretTypeStruct> TurretTypes;

struct TurretSpawnOffset {
    var class<Vehicle> TurretClass;
    var vector SpawnOffset;
};
var config array<TurretSpawnOffset> TurretSpawnOffsets;

const MSG_MaxTurrets = 0x1000;

var localized string MsgMaxTurrets, SelectionTitle;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReceiveTurretType;
}

static function vector GetSpawnOffset(class<Vehicle> TurretClass) {
    local int i;
    
    for(i = 0; i < default.TurretSpawnOffsets.Length; i++) {
        if(ClassIsChildOf(TurretClass, default.TurretSpawnOffsets[i].TurretClass)) {
            return default.TurretSpawnOffsets[i].SpawnOffset;
        }
    }
    return vect(0, 0, 0);
}

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_MaxTurrets:
			return default.MsgMaxTurrets;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int i;

	Super.GiveTo(Other, Pickup);
	
	for(i = 0; i < TurretTypes.Length; i++)
		ClientReceiveTurretType(i, TurretTypes[i]);
}

simulated function ClientReceiveTurretType(int i, TurretTypeStruct T)
{
    if(Role < ROLE_Authority) {
        if(i == 0)
            TurretTypes.Length = 0;

        TurretTypes[i] = T;
    }
}

function bool CanActivate()
{
	if(SelectedOption < 0)
		CostPerSec = 0; //no cost until selection

	if(!Super.CanActivate())
		return false;
	
	if(InstigatorRPRI.Turrets.Length >= InstigatorRPRI.MaxTurrets)
	{
		Msg(MSG_MaxTurrets);
		return false;
	}
	
	return true;
}

function Actor SpawnActor(class<Actor> SpawnClass, vector SpawnLoc, rotator SpawnRot)
{
    local class<Vehicle> TurretClass;
	local FriendlyTurretController C;
	local Vehicle T;
    
    TurretClass = class<Vehicle>(SpawnClass);
    SpawnLoc += GetSpawnOffset(TurretClass);
    
	T = Vehicle(Super.SpawnActor(SpawnClass, SpawnLoc, SpawnRot));
	if(T != None) {
        T.bTeamLocked = true;
        T.SetTeamNum(Instigator.Controller.GetTeamNum());

        if(T.Controller != None) {
            T.Controller.Destroy();
        
            C = Spawn(class'FriendlyTurretController',,, SpawnLoc, Instigator.Rotation);
            C.SetMaster(Instigator.Controller);
            C.Possess(T);
        }
		
		if(InstigatorRPRI != None)
			InstigatorRPRI.AddTurret(T);
	}
	return T;
}

function OnSelection(int i)
{
	CostPerSec = TurretTypes[i].Cost;
	Cooldown = TurretTypes[i].Cooldown;
	SpawnActorClass = TurretTypes[i].TurretClass;
}

simulated function string GetSelectionTitle()
{
	return SelectionTitle;
}

simulated function int GetNumOptions()
{
	return TurretTypes.Length;
}

simulated function string GetOption(int i)
{
	return TurretTypes[i].TurretClass.default.VehicleNameString;
}

simulated function int GetOptionCost(int i) {
	return TurretTypes[i].Cost;
}

function int SelectBestOption() {
    local Controller C;
    local int i;
    
    C = Instigator.Controller;
    if(C != None) {
        //The AI assumes that the best options are listed last
        for(i = TurretTypes.Length - 1; i >= 0; i--) {
            if(C.Adrenaline >= TurretTypes[i].Cost && FRand() < 0.5) {
                return i;
            }
        }
        
        //None
        return -1;
    } else {
        return Super.SelectBestOption();
    }
}

function BotWhatNext(Bot Bot) {
    //Only if defending
	if(Bot.Squad != None && Bot.Squad.IsDefending(Bot)) {
        Super.BotWhatNext(Bot);
    }
}

defaultproperties {
	SelectionTitle="Pick a turret to summon:"
	MsgMaxTurrets="You cannot spawn any more turrets at this time."

	bSelection=true
    
	ArtifactID="TurretSummon"
	Description="Constructs a floor sentinel."
	ItemName="Turret Constructor"
	PickupClass=Class'ArtifactPickup_TurretSummon'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.TurretSummon'
	HudColor=(B=192,G=128,R=128)
	CostPerSec=0
	Cooldown=0

	TurretTypes(0)=(TurretClass=class'RPGSentinelTurret',Cost=0,Cooldown=5)
    TurretSpawnOffsets(0)=(TurretClass=class'UT2k4Assault.ASVehicle_Sentinel_Floor',SpawnOffset=(Z=65))
}
