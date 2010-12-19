class HealingBlastCharger extends BlastCharger;

var float MinHealing, MaxHealing;
var int MaxHealth;
var float EXPMultiplier;

function DoEffect()
{
	local float healingScale, dist;
	local vector dir;
	local Controller C;
	local Pawn P;
	local int HealthGiven;
	local int localMaxHealth;
	local XPawn xP;

	if (Instigator == None && InstigatorController != None)
		Instigator = InstigatorController.Pawn;

	if(Instigator != None)
	{
		for(C = Level.ControllerList; C != None; C = C.NextController)
		{
			if(
				C.Pawn != None &&
				C.Pawn.Health > 0 &&
				C.SameTeamAs(InstigatorController) &&
				VSize(C.Pawn.Location - Location) <= Radius &&
				FastTrace(C.Pawn.Location, Location)
			)
			{
				P = C.Pawn;

				if(bAffectInstigator || P != Instigator)
				{
					localMaxHealth = MaxHealth;

					// limit if booster in progress
					xP = xPawn(P);
					if(xP != None && xP.CurrentCombo != None && xP.CurrentCombo.Name == 'ComboDefensive' )
						localMaxHealth = class'WeaponHealer'.default.MaxHealth;	 //in booster, lets not mess it up

					// heal them
					dir = C.Pawn.Location - Location;
					dist = FMax(1,VSize(dir));
					healingScale = 1 - FMax(0,dist/Radius);

					HealthGiven = max(1, (healingScale * (MaxHealing-MinHealing)) + MinHealing);
					if(HealthGiven > 0)
						class'HealableDamageGameRules'.static.Heal(P, HealthGiven, Instigator, localMaxHealth, EXPMultiplier, true);
				}
			}
		}
	}
	
	Destroy();
}

defaultproperties
{
	bAffectInstigator=True
	bBotsBeAfraid=False
	ChargeTime=2.000000
	MaxHealth=100
	MaxHealing=400.000000
	MinHealing=50.000000
	Radius=2200.000000
	ChargeEmitterClass=class'HealingChargeEmitter'
	ExplosionClass=class'HealingExplosion'
}
