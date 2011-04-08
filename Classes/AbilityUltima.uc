class AbilityUltima extends RPGAbility;

var config float BaseDelay; //should at least be equal to the max level
var config bool bAllowSuicide; //should Ultima trigger when you killed yourself?

var int KillCount; //Kill count in current spawn

replication
{
	reliable if(Role == ROLE_Authority)
		BaseDelay;
	
	reliable if(Role == ROLE_Authority && bNetDirty)
		KillCount;
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	KillCount = 0; //new spawn
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	local Pawn P;
	local UltimaCharger UC;
	local AbilityVehicleEject EjectorSeat;

	if(bAlreadyPrevented)
		return false;

	if(Killed.Controller == Killer && !bAllowSuicide)
		return false;

	if(DamageType == class'Suicided' /* TODO: && !default.bAllowSuicide */)
		return false;  

	if(Vehicle(Killed) != None) 
	{
		EjectorSeat = AbilityVehicleEject(RPRI.GetOwnedAbility(class'AbilityVehicleEject'));
		if(EjectorSeat != None && EjectorSeat.CanEjectDriver(Vehicle(Killed)))
			return false;
 	}

	P = Killed;
	if(Vehicle(P) != None)
		P = Vehicle(P).Driver;

	if(Killed.Location.Z > Killed.Region.Zone.KillZ && KillCount > 0)
	{
		UC = Killed.Spawn(class'UltimaCharger', Killed.Controller,, Killed.Location);
		if(UC != None)
		{
			UC.SetChargeTime(FMax(float(MaxLevel), BaseDelay) - float(AbilityLevel));
		}
		else
		{
			Warn("Failed to spawn Ultima charger for" @ Killed.GetHumanReadableName());
		}
	}

	return false;
}

function ScoreKill(Controller Killer, Controller Killed, bool bOwnedByKiller)
{
	local Pawn P;
	
	if(Killer == Killed || Killer.SameTeamAs(Killed))
		return;
	
	P = Killer.Pawn;
	
	if(P == None)
		return;
	
	if(Vehicle(P) != None)
		P = Vehicle(P).Driver;

	if(bOwnedByKiller && (Killed.Pawn == None || (Killed.Pawn.HitDamageType != class'DamTypeTitanUltima' && Killed.Pawn.HitDamageType != class'DamTypeUltima')))
		KillCount++;
}

defaultproperties
{
	AbilityName="Ultima"
	Description="When you die and you have at least scored one kill in that respective life, you will cause a huge explosion.|Level 1 waits 4 seconds after you died, each higher level wait 1 second less."
	MaxLevel=5
	bUseLevelCost=true
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityUltimaShield',Level=1)
	ForbiddenAbilities(1)=(AbilityClass=class'AbilityGhost',Level=1)
	RequiredAbilities(0)=(AbilityClass=class'AbilityDamageBonus',Level=6)
	LevelCost(0)=60
	LevelCost(1)=40
	LevelCost(2)=20
	LevelCost(3)=40
	LevelCost(4)=20
	BaseDelay=5.0
	bAllowSuicide=False //true for TC06
}
