class Artifact_SummonTotem extends ArtifactBase_Construct;

struct TotemTypeStruct
{
	var class<RPGTotem> TotemClass;
	var int Cost;
	var int Cooldown;
};
var config array<TotemTypeStruct> TotemTypes;

const MSG_MaxTotems = 0x1000;

var localized string MsgMaxTotems, SelectionTitle;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReceiveTotemType;
}

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_MaxTotems:
			return default.MsgMaxTotems;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int i;

	Super.GiveTo(Other, Pickup);
	
	for(i = 0; i < TotemTypes.Length; i++)
		ClientReceiveTotemType(i, TotemTypes[i]);
}

simulated function ClientReceiveTotemType(int i, TotemTypeStruct T)
{
    if(Role < ROLE_Authority) {
        if(i == 0)
            TotemTypes.Length = 0;

        TotemTypes[i] = T;
    }
}

function bool CanActivate()
{
	if(SelectedOption < 0)
		CostPerSec = 0; //no cost until selection

	if(!Super.CanActivate())
		return false;
	
	if(InstigatorRPRI.Totems.Length >= InstigatorRPRI.MaxTotems) {
		Msg(MSG_MaxTotems);
		return false;
	}
	
	return true;
}

function Actor SpawnActor(class<Actor> SpawnClass, vector SpawnLoc, rotator SpawnRot)
{
	local RPGTotem Totem;
	
    SpawnLoc += vect(0, 0, 48);
    
	Totem = RPGTotem(Super.SpawnActor(SpawnClass, SpawnLoc, SpawnRot));
	if(Totem != None) {
        Totem.SetOwner(None);
        Totem.SetTeamNum(Instigator.Controller.GetTeamNum());
        RPGTotemController(Totem.Controller).SetMaster(Instigator.Controller);
        
        if(InstigatorRPRI != None) {
            InstigatorRPRI.AddTotem(Totem);
        }
	}
	return Totem;
}

function OnSelection(int i)
{
	CostPerSec = TotemTypes[i].Cost;
	Cooldown = TotemTypes[i].Cooldown;
	SpawnActorClass = TotemTypes[i].TotemClass;
}

simulated function string GetSelectionTitle()
{
	return SelectionTitle;
}

simulated function int GetNumOptions()
{
	return TotemTypes.Length;
}

simulated function string GetOption(int i)
{
	return TotemTypes[i].TotemClass.default.VehicleNameString;
}

simulated function int GetOptionCost(int i) {
	return TotemTypes[i].Cost;
}

function int SelectBestOption() {
    local Controller C;
    local int i;
    
    C = Instigator.Controller;
    
    if(C != None) {
        //Simply try and pick a random one
        while(i < 10) {
            i = Rand(TotemTypes.Length);
            if(C.Adrenaline >= TotemTypes[i].Cost) {
                return i;
            }
        }
        
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

defaultproperties
{
	SelectionTitle="Pick a totem to construct:"
	MsgMaxTotems="You cannot construct any more totems at this time."

	bSelection=true

	ArtifactID="TotemConstruct"
	Description="Constructs a totem of your choice."
	ItemName="Totem Constructor"
	PickupClass=Class'ArtifactPickup_Totem'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Totem'
	HudColor=(B=96,G=96,R=192)
	CostPerSec=0
	Cooldown=0

	TotemTypes(0)=(TotemClass=class'Totem_Heal',Cost=0,Cooldown=1)
	TotemTypes(1)=(TotemClass=class'Totem_Lightning',Cost=0,Cooldown=1)
	TotemTypes(2)=(TotemClass=class'Totem_Repair',Cost=0,Cooldown=1)
}
