class Ability_Ultima extends RPGAbility;

var config float BaseDelay; //should at least be equal to the max level
var config bool bAllowSuicide; //should Ultima trigger when you killed yourself?

var int KillCount; //Kill count in current spawn

var float TryRadiusMin, TryRadiusMax; //if spawning a charger fails, try randomly around the player

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
	local Blast_Ultima UC;
	local Pawn P;
	local Ability_VehicleEject EjectorSeat;
	local int Tries;
	local vector TryLocation;

	if(bAlreadyPrevented)
		return false;

	if(Killed.Controller == Killer && !bAllowSuicide)
		return false;

	if(DamageType == class'Suicided')
		return false;  

	if(Vehicle(Killed) != None) 
	{
		EjectorSeat = Ability_VehicleEject(RPRI.GetOwnedAbility(class'Ability_VehicleEject'));
		if(EjectorSeat != None && EjectorSeat.CanEjectDriver(Vehicle(Killed)))
			return false;
 	}

	P = Killed;
	if(Vehicle(P) != None)
		P = Vehicle(P).Driver;

	if(Killed.Location.Z > Killed.Region.Zone.KillZ && KillCount > 0)
	{
		if(SpawnCharger(Killed.Location) == None)
		{
			//Location is blocked by something, try somewhere else
			for(Tries = 0; Tries < 25; Tries++)
			{
				TryLocation = Killed.Location +
					VRand() * (TryRadiusMin + FRand() * (TryRadiusMax - TryRadiusMin));
				
				UC = SpawnCharger(TryLocation);
				if(UC != None)
					break;
			}
			
			if(UC == None)
				Warn("Failed to spawn Ultima charger for" @ Killed.GetHumanReadableName());
		}
	}

	return false;
}

function ScoreKill(Controller Killed, class<DamageType> DamageType)
{
	if(DamageType != class'DamTypeTitanUltima' && DamageType != class'DamTypeUltima')
		KillCount++;
}

function Blast_Ultima SpawnCharger(vector ChargerLocation)
{
	local Blast_Ultima UC;

	UC = Spawn(class'Blast_Ultima', RPRI.Controller,, ChargerLocation);
	if(UC != None)
		UC.SetChargeTime(FMax(float(MaxLevel), BaseDelay) - float(AbilityLevel));
	
	return UC;
}

defaultproperties
{
	StatusIconClass=class'StatusIcon_Ultima'
	
	AbilityName="Ultima"
	Description="When you die and you have at least scored one kill in that respective life, you will cause a huge explosion.|Level 1 waits 4 seconds after you died, each higher level wait 1 second less."
	MaxLevel=5
	bUseLevelCost=true
	ForbiddenAbilities(0)=(AbilityClass=class'Ability_UltimaShield',Level=1)
	ForbiddenAbilities(1)=(AbilityClass=class'Ability_Ghost',Level=1)
	LevelCost(0)=60
	LevelCost(1)=40
	LevelCost(2)=20
	LevelCost(3)=40
	LevelCost(4)=20
	BaseDelay=5.0
	bAllowSuicide=False //true for TC06
	
	TryRadiusMin=32
	TryRadiusMax=48
	
	Category=class'AbilityCategory_Misc'
}
