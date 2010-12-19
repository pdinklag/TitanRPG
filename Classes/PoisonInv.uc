class PoisonInv extends Inventory;

enum EPoisonMode
{
	PM_Absolute, //drain an absolute amount of health per time unit (AbsDrainPerLevel)
	PM_Percentage, //drain a percentage of the current health per time unit (PercDrainPerLevel)
	PM_Curve //use the TitanRPG curve (BasePercentage and Curve)
};
var EPoisonMode PoisonMode;

var float BasePercentage;
var float Curve;

var int AbsDrainPerLevel;
var float PercDrainPerLevel;

var int MinHealth; //cannot drain below this

var RPGRules RPGRules;

var Controller InstigatorController;
var Pawn PawnOwner;
var int Modifier;

var bool bAbsoluteDamage;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		PawnOwner;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Instigator != None)
		InstigatorController = Instigator.Controller;

	SetTimer(1, true);
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local Pawn OldInstigator;

	if (InstigatorController == None)
		InstigatorController = Other.DelayedDamageInstigatorController;

	//want Instigator to be the one that caused the poison
	OldInstigator = Instigator;
	Super.GiveTo(Other);
	PawnOwner = Other;
	Instigator = OldInstigator;
}

simulated function Timer()
{
	local int PoisonDamage;

	if(Role == ROLE_Authority)
	{
		if(Owner == None)
		{
			Destroy();
			return;
		}
		
		if(MinHealth == 0 || PawnOwner.Health > MinHealth)
		{
			if(Instigator == None && InstigatorController != None)
				Instigator = InstigatorController.Pawn;

			switch(PoisonMode)
			{
				case PM_Absolute:
					PoisonDamage = AbsDrainPerLevel * Modifier;
					break;
					
				case PM_Percentage:
					PoisonDamage = Modifier * PercDrainPerLevel * PawnOwner.Health;
					break;
					
				case PM_Curve:
					PoisonDamage = int(float(PawnOwner.Health) * (Curve ** (float(Modifier - 1)) * BasePercentage));
					break;
			}
		
			if(PoisonDamage > 0 && !(PawnOwner.Controller != None && PawnOwner.Controller.bGodMode))
			{
				if(MinHealth > 0)
				{
					PawnOwner.Health = Max(MinHealth, PawnOwner.Health - PoisonDamage);
				}
				else if(PoisonDamage >= PawnOwner.Health)
				{
					//Kill
					PawnOwner.TakeDamage(PoisonDamage, Instigator, PawnOwner.Location, vect(0, 0, 0), class'DamTypePoison');
				}
				else
				{
					PawnOwner.Health -= PoisonDamage;
				}
				
				if(Instigator != None && Instigator != PawnOwner.Instigator) //exp only for harming others.
					RPGRules.AwardEXPForDamage(Instigator.Controller, class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller), PawnOwner, PoisonDamage);
			}
		}
	}

	if(Level.NetMode != NM_DedicatedServer && PawnOwner != None)
	{
		PawnOwner.Spawn(class'GoopSmoke');
		if (PawnOwner.IsLocallyControlled() && PlayerController(PawnOwner.Controller) != None)
			PlayerController(PawnOwner.Controller).ReceiveLocalizedMessage(class'PoisonConditionMessage', 0);
	}
}

defaultproperties
{
	bOnlyRelevantToOwner=False
	PoisonMode=PM_Curve
}
