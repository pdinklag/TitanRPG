Class HealableDamageGameRules extends GameRules
	config(TitanRPG);

var config int MaxHealthBonus;

var config int SelfHealingCap;
var config float SelfHealingMultiplier;

var Material HealOverlay;
var Sound HealSound;

function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local int DamageRV;

	DamageRV = Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

	if(
		injured != None &&
		!injured.IsA('Monster') &&
		instigatedBy != None &&
		instigatedBy.Controller != None &&
		(!injured.IsA('Vehicle') || !Vehicle(Injured).IsVehicleEmpty()) &&
		(injured.Controller == None || !injured.Controller.SameTeamAs(instigatedBy.Controller))
	)
	{
		DoHealableDamage(DamageRV, Injured);
	}
	
	return DamageRV;
}

function DoHealableDamage(int Damage, Pawn Injured)
{
	local HealableDamageInv Inv;
	
	Inv = HealableDamageInv(injured.FindInventoryType(class'HealableDamageInv'));
	if(Inv == None)
	{
		Inv = injured.spawn(class'HealableDamageInv');
		Inv.giveTo(injured);
	}

	Inv.Damage += Damage;
	
	if(Inv.Damage > Injured.HealthMax + MaxHealthBonus)
		Inv.Damage = Injured.HealthMax + MaxHealthBonus;
}

/*
	Centralized healing function ~pd
	Returns whether any health was given.
*/
static function bool Heal(Pawn Healed, int Amount, Pawn Healer, int OverHealthMax, float ExpMultiplier, optional bool bMessage)
{
	local bool result;
	local array<Pawn> Passengers;
	local int x;
	local HealableDamageInv Inv;
	local int ValidHealthGiven;
	local RPGPlayerReplicationInfo RPRI;

	if(Healed == None || Amount <= 0)
		return false;

	if(Vehicle(Healed) != None)
	{
		//Heal all passengers
		Passengers = class'Util'.static.GetAllPassengers(Vehicle(Healed));
		for(x = 0; x < Passengers.Length; x++)
			result = result || Heal(Passengers[x], Amount, Healer, OverHealthMax, ExpMultiplier);
			//RECURSION!
			
		return result;
	}
	
	if(Healed == Healer && Amount > default.SelfHealingCap)
		Amount = Max(1, int(float(Amount) * default.SelfHealingMultiplier));
	
	Healed.GiveHealth(Amount, Healed.HealthMax + OverHealthMax);

	if(Healer == None)
		return true;

	Inv = HealableDamageInv(Healed.FindInventoryType(class'HealableDamageInv'));
	if(Inv != None)
	{
		ValidHealthGiven = Min(Amount, Inv.Damage);
		if(ValidHealthGiven > 0)
		{
			if(
				ExpMultiplier > 0.f &&
				Healer != Healed &&
				FriendlyMonsterController(Healed.Controller) == None
			)
			{
				RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Healer.Controller);
				
				if (RPRI != None)
					RPRI.AwardExperience(ExpMultiplier * float(ValidHealthGiven));
				else
					Warn("No RPGPlayerReplicationInfo for " $ Healer.Controller.GetHumanReadableName() $ ", healing exp not granted!");
			}

			Inv.Damage -= ValidHealthGiven;
		}
		
		if(Inv.Damage > (Healed.HealthMax + OverHealthMax) - Healed.Health)
			Inv.Damage = Max(0, (Healed.HealthMax + OverHealthMax) - Healed.Health);
	}
	
	class'SyncOverlayMaterial'.static.Sync(Healed, default.HealOverlay, 1.0, true);
	
	if(bMessage && PlayerController(Healed.Controller) != None)
		PlayerController(Healed.Controller).ReceiveLocalizedMessage(class'HealedConditionMessage', 0, Healer.PlayerReplicationInfo, Healed.PlayerReplicationInfo);
	
	class'Util'.static.PlayLoudEnoughSound(Healed, default.HealSound, 3);
	
	return true;
}

defaultproperties
{
	HealSound=Sound'<? echo($packageName); ?>.SoundEffects.Heal'
	HealOverlay=Shader'<? echo($packageName); ?>.Overlays.BlueShader'
	SelfHealingCap=0
	SelfHealingMultiplier=0.250000
	MaxHealthBonus=150
}
