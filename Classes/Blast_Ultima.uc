class Blast_Ultima extends Blast;

var config float Damage, MomentumTransfer;
var config class<DamageType> DamageType;

var config bool bIgnoreUltimaShield, bIgnoreProtectionGun;

var config int DamageStages;

var int DamageStage;

function DoDamage(float LocalRadius)
{
	local Actor victims;
	local float damageScale, dist;
	local vector dir;
	local Pawn P;
	local RPGPlayerReplicationInfo RPRI;
	local TransBeacon TB;

	if (Instigator == None && InstigatorController != None)
		Instigator = InstigatorController.Pawn;

	if(bHurtEntry)
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors(class'Actor', victims, LocalRadius, Location)
	{
		//protect TransBeacon
		if(!bIgnoreUltimaShield)
		{
			TB = TransBeacon(victims);
			if(TB != None && TB.Instigator != None)
			{
				RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(TB.Instigator.Controller);
				if(RPRI != None && RPRI.HasAbility(class'Ability_UltimaShield') > 0)
					continue;
			}

			P = Pawn(victims);
			if (P != None && Vehicle(P) == None && P.PlayerReplicationInfo != None)
			{
				RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(P.Controller);
				if(RPRI != None && RPRI.HasAbility(class'Ability_UltimaShield') > 0)
					continue;
			}
		}
		
		if(!bIgnoreProtectionGun)
		{
			P = Pawn(victims);
			if(P != None)
			{
                //TODO effect system
				if(class'WeaponModifier_Protection'.static.GetFor(P.Weapon) != None ||
					class'Artifact_Protection'.static.IsActiveFor(P))
				{
					continue;
				}
			}
		}
		
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if(
			victims != Self &&
			FluidSurfaceInfo(victims) == None &&
			(
				(bAffectInstigator && victims == Instigator) ||
				(P == None || P.Controller == None || TeamGame(Level.Game) == None || TeamGame(Level.Game).FriendlyFireScale > 0 || !P.Controller.SameTeamAs(Controller(Owner)))
			)
		)
		{
			if(P == None || Level.TimeSeconds > P.SpawnTime + DeathMatch(Level.Game).SpawnProtectionTime)
			{
				dir = victims.Location - Location;
				dist = FMax(1,VSize(dir));
				dir = dir/dist;

				damageScale = 1 - FMax(0, (dist - victims.CollisionRadius) / LocalRadius);
				
				//set HitDamageType early so AbilityUltima.ScoreKill() can use it
				if (Pawn(victims) != None)
					Pawn(victims).HitDamageType = DamageType;

				victims.SetDelayedDamageInstigatorController(InstigatorController);

				victims.TakeDamage (
					damageScale * Damage,
					Instigator,
					victims.Location - 0.5 * (victims.CollisionHeight + victims.CollisionRadius) * dir,
					(damageScale * MomentumTransfer * dir),
					DamageType
				);
			} 
			else if(xPawn(victims) != None)
			{
				xPawn(victims).SetOverlayMaterial(xPawn(victims).ShieldHitMat, xPawn(victims).ShieldHitMatTime, false);
			}
		}
	}
	bHurtEntry = false;
}

simulated function Timer()
{
	if(!bDoneCharging)
	{
		Super.Timer(); //THIS IS IMPORTANT!!!!! ~pd
	}
	else if(Role == ROLE_Authority)
	{
		DamageStage++;
		DoDamage(Radius * float(DamageStage) / float(DamageStages));

		if(DamageStage == 1)
			SetTimer(0.5, false);
		else if(DamageStage < DamageStages)
			SetTimer(0.2, false);
		else
			Destroy();
	}
}

function DoEffect()
{
	DamageStage = 0;
	Timer();
}

defaultproperties
{
	bIgnoreUltimaShield=False
	bIgnoreProtectionGun=False
	bAllowDeadInstigator=True

	bBotsBeAfraid=True
	Radius=1750.000000
	
	Damage=250.000000
	DamageStages=6
	MomentumTransfer=200000.000000

	//TitanRPG defaults
	DamageType=class'DamTypeTitanUltima'
	ChargeEmitterClass=class'FX_BlastCharger_TitanUltima'
	ExplosionClass=class'FX_BlastExplosion_TitanUltima'
	
	//As a reference, the original DruidsRPG emitters (you can set them in the INIs):
	//DamageType=class'DamTypeUltima'
	//ChargeEmitterClass=class'FX_BlastCharger_Ultima'
	//ExplosionClass=class'FX_BlastExplosion_Ultima'
}
