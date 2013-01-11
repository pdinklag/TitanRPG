class Artifact_LightningRod extends RPGArtifact;

var config float TargetRadius;
var config int DamagePerHit;

var config int ExtraCostPerPlayer;
var config int ExtraCostPerMine;

var config bool bMustBeMoving;

const MSG_NotWithTrans = 0x1000;

var localized string NotWithTransMessage;

var class<xEmitter> HitEmitterClass;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_NotWithTrans:
			return default.NotWithTransMessage;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function BotFightEnemy(Bot Bot)
{
	local float Chance;

	if(!bActive)
	{
		if(HasActiveArtifact(Instigator))
			return;
			
		if(class'WeaponModifier_LightningConduction'.static.GetFor(Bot.Enemy.Weapon) != None)
			return;
	
		if(
			Bot.bEnemyIsVisible &&
			Bot.CombatStyle >= 0 &&
			Bot.Skill >= 3 && 
			Bot.Adrenaline >= 50 &&
			VSize(Bot.Enemy.Location - Instigator.Location) <= TargetRadius)
		{
			Chance = FMin(0.4, (Bot.StrafingAbility + 1.f) / 4.f);
			Chance += 0.05 * (Bot.Skill - 3); //max 0.6
			
			if(Bot.Enemy.PlayerReplicationInfo != None &&
				Bot.Enemy.PlayerReplicationInfo.HasFlag != None)
				Chance += 0.15; //max 0.75
				
			if(TransLauncher(Bot.Enemy.Weapon) != None)
				Chance += 0.1; //max 0.85
			
			if(Instigator.HasUDamage())
				Chance += 0.75; //max 1.1
		
			if(FRand() < Chance)
				Activate();
		}
	}
	else
	{
		if(
			class'WeaponModifier_LightningConduction'.static.GetFor(Bot.Enemy.Weapon) != None ||
			VSize(Bot.Enemy.Location - Instigator.Location) > TargetRadius)
		{
			Activate();
		}
	}
}

function BotLoseEnemy(Bot Bot)
{
	if(bActive)
		Activate(); //deactivate
}

function BotWhatNext(Bot Bot)
{
	if(bActive && (Bot.Enemy == None || !Bot.bEnemyIsVisible))
		Activate();
}

function bool CanActivate()
{
	//Don't allow rodding with a translocator -pd
	if(TransLauncher(Instigator.Weapon) != None) {
        Msg(MSG_NotWithTrans);
        return false;
	}

	return Super.CanActivate();
}

state Activated
{
	function Timer()
	{
		local Controller C, NextC;
		local ONSMineProjectile Mine;
		local int Targets, MineTargets;
		local xEmitter HitEmitter;
		local vector HitLocation, HitNormal;
		local rotator Dir;
		local Actor TracedActor;
		local int FinalDamage;

		//If the Instigator switches to a translocator, turn the rod off! -pd
		if(TransLauncher(Instigator.Weapon) != None) {
				Activate();	//Don't be confused, this deactivates it...
		}
		
		//need to be moving for it to do anything... so can't just sit somewhere and camp
		if(bMustBeMoving && VSize(Instigator.Velocity) ~= 0)
		{
			CostPerSec = default.CostPerSec;
			return;
		}

		foreach DynamicActors(class'ONSMineProjectile', Mine)
		{
			if (Mine.TeamNum != Instigator.Controller.GetTeamNum()
			    && VSize(Mine.Location - Instigator.Location) < TargetRadius && FastTrace(Mine.Location, Instigator.Location) ) {
				HitEmitter = Spawn(HitEmitterClass,,, Instigator.Location, rotator(Mine.Location - Instigator.Location));
				if (HitEmitter != None)
					HitEmitter.mSpawnVecA = Mine.Location;
				Mine.Explode(Mine.Location, vect(0,0,1));
				MineTargets++;
			}
		}

		C = Level.ControllerList;
		while (C != None)
		{
			// get next controller here because C may be destroyed if it's a nonplayer and C.Pawn is killed
			NextC = C.NextController;
			if ( C.Pawn != None && C.Pawn != Instigator && C.Pawn.Health > 0 && !C.SameTeamAs(Instigator.Controller) &&
			     VSize(C.Pawn.Location - Instigator.Location) < TargetRadius && C.Level.TimeSeconds >= C.Pawn.SpawnTime + DeathMatch(C.Level.Game).SpawnProtectionTime)
			{
				TracedActor = Trace(HitLocation, HitNormal, C.Pawn.Location, Instigator.Location, True);
				if (TracedActor == C.Pawn)
				{
					//Check C.Pawn for a Protection Weapon and calculate the final damage! -pd

					FinalDamage = DamagePerHit;

        			HitEmitter = spawn(HitEmitterClass,,, Instigator.Location, rotator(C.Pawn.Location - Instigator.Location));

					if (HitEmitter != None)
						HitEmitter.mSpawnVecA = C.Pawn.Location;

					HitLocation = C.Pawn.Location;
					Dir = rotator(C.Pawn.Location - Instigator.Location);
					HitLocation += vect(-10, 0, 0) >> Dir; //(c) Wulff ? should credit him here ;)

					if(FinalDamage > 0)
						C.Pawn.TakeDamage(FinalDamage, Instigator, HitLocation, vect(0,0,0), class'DamTypeLightningRod');

					Targets++;
				}
			}
			C = NextC;
		}

		CostPerSec = default.CostPerSec + Targets * ExtraCostPerPlayer + MineTargets * ExtraCostPerMine;
	}
	
	function BeginState()
	{
		Super.BeginState();
		CostPerSec = default.CostPerSec;
		SetTimer(1.0, true);
	}

	function EndState()
	{
		CostPerSec = default.CostPerSec;
		SetTimer(0, false);
		Super.EndState();
	}
}

defaultproperties
{
	ActivateSound=Sound'TitanRPG.SoundEffects.Rod'
	bAllowInVehicle=False
	bMustBeMoving=True
	TargetRadius=2048.000000
	DamagePerHit=30
	ExtraCostPerPlayer=8
	ExtraCostPerMine=2
	NotWithTransMessage="You cannot use this artifact while using the Translocator."
	HitEmitterClass=Class'XEffects.LightningBolt'
	CostPerSec=4
	bExclusive=True
	MinActivationTime=1.000000
	ArtifactID="Rod"
	Description="Fires lightnings at nearby enemies."
	PickupClass=Class'ArtifactPickup_LightningRod'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.rod'
	ItemName="Lightning Rod"
}
