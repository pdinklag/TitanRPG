class ArtifactTripleDamage extends RPGArtifact;

var Weapon LastWeapon;
var config float DoubleDamageScale;

function BotFightEnemy(Bot Bot)
{
	local float Chance;

	if(ONSRV(Instigator) != None && ONSPRV(Instigator) != None)
		return;

	if(!bActive)
	{
		if(HasActiveArtifact(Instigator))
			return;
			
		if(Instigator.HasUDamage())
			return;
	
		if(
			Bot.bEnemyIsVisible &&
			Bot.CombatStyle >= 0 &&
			Bot.Skill >= 4 && 
			Bot.Adrenaline >= 3 * CostPerSec * MinActivationTime &&
			Bot.Enemy.Health > 50 &&
			FRand() < FMin(0.666667, Bot.Aggressiveness))
		{
			Chance = FMin(0.3, Bot.Aggressiveness);
			Chance += FMin(0.3, (Bot.Accuracy + 1.f) / 4.f);
			
			Chance += 0.05 * (Bot.Skill - 4); //max 0.75
			
			if(Bot.Adrenaline >= 100)
				Chance += 0.05; //max 0.8
				
			if(WeaponRetaliation(Bot.Enemy.Weapon) != None)
				Chance -= 0.25;
				
			if(Bot.Enemy.Health >= 100)
				Chance += 0.05; //max 0.85
				
			if(Bot.Enemy.PlayerReplicationInfo != None &&
				Bot.Enemy.PlayerReplicationInfo.HasFlag != None)
				Chance += 0.15; //max 1.00
			
			if(FRand() < Chance)
				Activate();
		}
	}
	else
	{
		if(Bot.Enemy.Health <= 10)
			Activate();
	}
}

function BotWhatNext(Bot Bot)
{
	if(bActive && (Bot.Enemy == None || !Bot.bEnemyIsVisible))
		Activate();
}

function BotLoseEnemy(Bot Bot)
{
	if(bActive)
		Activate(); //deactivate
}

function bool CanActivate()
{
	if(class'ArtifactLightningRod'.static.IsActiveFor(Instigator) ||
		class'ArtifactDoubleModifier'.static.IsActiveFor(Instigator) ||
		class'ArtifactProtection'.static.IsActiveFor(Instigator))
	{
		return false;
	}

	if(Instigator.HasUDamage())
		return false;
		
	return Super.CanActivate();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();
	
		Instigator.DamageScaling *= DoubleDamageScale;

		Timer();
		SetTimer(0.5, true);
	}
	
	function Timer()
	{
		local float EstimatedTimeLeft;
		local Pawn P;
		
		if(Vehicle(Instigator) != None)
			P = Vehicle(Instigator).Driver;
		else
			P = Instigator;
		
		if(P != None)
		{
			EstimatedTimeLeft = Instigator.Controller.Adrenaline / CostPerSec;
			
			P.EnableUDamage(EstimatedTimeLeft);
			if(xPawn(P) != None)
			{
				if(TripleDamageTimer(xPawn(P).UDamageTimer) == None)
				{
					if(xPawn(P).UDamageTimer != None)
						xPawn(P).UDamageTimer.Destroy();

					xPawn(P).UDamageTimer = Spawn(class'TripleDamageTimer', P);
				}
				xPawn(P).UDamageTimer.SetTimer(xPawn(P).UDamageTime - Level.TimeSeconds - 3, false);
			}
		}
	}
	
	function EndState()
	{
		local Pawn P;
		
		if(Vehicle(Instigator) != None)
			P = Vehicle(Instigator).Driver;
		else
			P = Instigator;

		SetTimer(0, false);
		if (P != None)
		{
			Instigator.DamageScaling /= DoubleDamageScale;

			P.DisableUDamage();
			
			if(xPawn(P) != None && xPawn(P).UDamageTimer != None)
				xPawn(P).UDamageTimer.Destroy();
		}
		
		Super.EndState();
	}
}

defaultproperties
{
	ActivateSound=Sound'PickupSounds.UDamagePickUp'
	DoubleDamageScale=1.500000
	MinActivationTime=1.000000
	CostPerSec=13
	HudColor=(B=128,G=0)
	ArtifactID="Triple"
	Description="Makes you deal three times as much damage as usual."
	PickupClass=Class'ArtifactPickupTripleDamage'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.Triple'
	ItemName="Triple Damage"
}
