class AbilityAura extends RPGAbility;

var config float HealInterval;
var config float HealRadius;

var array<FX_HealingBeam> HealEmitters;

replication
{
	reliable if(Role == ROLE_Authority && !bNetSyncComplete)
		HealInterval, HealRadius;
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	SetTimer(HealInterval, true);
}

function Timer()
{
	local Effect_Heal Heal;
	local FX_HealingBeam HealEmitter;
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
			FastTrace(Instigator.Location, P.Location)
		)
		{
			Heal = Effect_Heal(class'Effect_Heal'.static.Create(P, RPRI.Controller));
			if(Heal != None)
			{
				Heal.HealAmount = AbilityLevel * int(BonusPerLevel);
				Heal.Start();
			
				HealEmitter = Instigator.Spawn(class'FX_HealingBeam', Instigator);
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

	