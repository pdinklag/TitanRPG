class Artifact_UDamage extends RPGArtifact;

var config float UDamageScale;

const MSG_UDamage = 0x1000;

var localized string MSG_Text_UDamage;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_UDamage:
			return default.MSG_Text_UDamage;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

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
				
			if(class'WeaponModifier_Retaliation'.static.GetFor(Bot.Enemy.Weapon) != None)
				Chance -= 0.25;
				
			if(Bot.Enemy.Health >= 75)
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
	if(Instigator.HasUDamage())
	{
		Msg(MSG_UDamage);
		return false;
	}
		
	return Super.CanActivate();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();
	
		Instigator.DamageScaling *= UDamageScale;

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
			Instigator.DamageScaling /= UDamageScale;

			P.DisableUDamage();
			
			if(xPawn(P) != None && xPawn(P).UDamageTimer != None)
				xPawn(P).UDamageTimer.Destroy();
		}
		
		Super.EndState();
	}
}

defaultproperties
{
	MSG_Text_UDamage="You already have an active UDamage powerup."
	ActivateSound=Sound'PickupSounds.UDamagePickUp'
	UDamageScale=1.000000
	MinActivationTime=1.000000
	CostPerSec=8
	bExclusive=True
	HudColor=(B=128,G=0)
	ArtifactID="UDamage"
	Description="Makes you deal twice as much damage as usual."
	PickupClass=Class'ArtifactPickup_UDamage'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.DDamage'
	ItemName="Double Damage"
}
