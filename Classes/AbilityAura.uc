class AbilityAura extends RPGAbility;

var config float HealInterval;
var config float HealRadius;

var array<HealingBeamEffect> HealEmitters;

replication
{
	reliable if(Role == ROLE_Authority)
		HealInterval, HealRadius;
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	SetTimer(HealInterval, true);
}

function Timer()
{
	local HealingBeamEffect HealEmitter;
	local Pawn P;

	if(Instigator == None || Instigator.Health <= 0)
		return;
	
	CleanEmitters();
	
	if(Instigator.DrivenVehicle != None)
		return;

	if(VSize(Instigator.Velocity) ~= 0)
		return;
	
	foreach Instigator.VisibleCollidingActors(class'Pawn', P, HealRadius)
	{
		if(
			P != Instigator &&
			!P.IsA('Monster') &&
			!P.IsA('Vehicle') &&
			P.Health < P.HealthMax &&
			P.Controller != None &&
			P.Controller.SameTeamAs(RPRI.Controller) &&
			FastTrace(Instigator.Location, P.Location)
		)
		{
			if(class'HealableDamageGameRules'.static.Heal(P, AbilityLevel * int(BonusPerLevel), Instigator, 0, RPRI.HealingExpMultiplier, true))
			{
				HealEmitter = Instigator.Spawn(class'HealingBeamEffect', Instigator);
				HealEmitter.LinkedPawn = P;
				
				HealEmitters[HealEmitters.Length] = HealEmitter;
			}
		}
	}
}

function CleanEmitters()
{
	local int i;
	
	while(i < HealEmitters.Length)
	{
		if(HealEmitters[i] == None)
			HealEmitters.Remove(i, 1);
		else
			i++;
	}
}

event Destroyed()
{
	local int i;

	Super.Destroyed();

	for(i = 0; i < HealEmitters.Length; i++)
	{
		if(HealEmitters[i] != None)
			HealEmitters[i].Destroy();
	}
	
	HealEmitters.Remove(0, HealEmitters.Length);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatFloat(BonusPerLevel));
}

defaultproperties
{
	BonusPerLevel=1
	HealRadius=1024.000000
	HealInterval=1.000000
	AbilityName="Convalescing Aura"
	Description="Heals nearby teammates by $1 health per level per second."
	StartingCost=10
	CostAddPerLevel=0
	MaxLevel=5
	RequiredAbilities(0)=(AbilityClass=Class'AbilityLoadedMedic',Level=3)
}

	