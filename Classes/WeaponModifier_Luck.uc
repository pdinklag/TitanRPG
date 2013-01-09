class WeaponModifier_Luck extends RPGWeaponModifier;

var config float UDamageChanceBonus;
var float NextEffectTime;

var localized string LuckText, MisfortuneText;

function StartEffect() {
    Super.StartEffect();

	if (Modifier > 0)
		NextEffectTime = float(Rand(15) + 25) / (Modifier + 1);
	else
		NextEffectTime = (1.25 + FRand() * 1.25) / -(Modifier - 1);
}

function RPGTick(float dt) {
    local Pickup P;
	local class<Pickup> ChosenClass;
	local vector HitLocation, HitNormal, EndTrace;

	Super.RPGTick(dt);

	NextEffectTime -= dt;
	if(NextEffectTime <= 0)
	{
		Identify();
	
		if(Modifier < 0)
		{
			foreach Instigator.CollidingActors(class'Pickup', P, 300)
			{
				if(P.ReadyToPickup(0) && WeaponLocker(P) == None)
				{
					Spawn(class'FX_Misfortune',P,, P.Location);

					if (!P.bDropped && WeaponPickup(P) != None && WeaponPickup(P).bWeaponStay && P.RespawnTime != 0.0)
						P.GotoState('Sleeping');
					else
						P.SetRespawn();
					break;
				}
			}
			NextEffectTime = (1.25 + FRand() * 1.25) / -(Modifier - 1);
		}
		else
		{
			ChosenClass = ChoosePickupClass();
			if(ChosenClass != None)
			{
				EndTrace = Instigator.Location + vector(Instigator.Rotation) * Instigator.GroundSpeed;
				if(Instigator.Trace(HitLocation, HitNormal, EndTrace, Instigator.Location) != None)
				{
					HitLocation -= vector(Instigator.Rotation) * 40;
					P = spawn(ChosenClass,,, HitLocation);
				}
				else
				{
					P = spawn(ChosenClass,,, EndTrace);
				}

				if(P == None)
					return;
				
				P.RespawnTime = 0.0;
				P.bDropped = true;
				P.GotoState('Sleeping');

				NextEffectTime = float(Rand(15) + 25) / (Modifier + 1);
			}
		}
	}
}

//choose a pickup to spawn, favoring those that are most useful to Instigator
function class<Pickup> ChoosePickupClass()
{
	local array<class<Pickup> > Potentials;
	local Inventory Inv;
	local Weapon W;
	local class<Pickup> AmmoPickupClass;
	local int Count;

	if(Instigator.Health < Instigator.HealthMax)
	{
		Potentials[Potentials.Length] = class'HealthPack';
		Potentials[Potentials.Length] = class'MiniHealthPack';
	}
	else
	{
		if(Instigator.Health < Instigator.SuperHealthMax)
			Potentials[Potentials.Length] = class'MiniHealthPack';
		
		if(xPawn(Instigator) != None && xPawn(Instigator).CanUseShield(class'ShieldPack'.default.ShieldAmount) > 0)
			Potentials[Potentials.Length] = class'ShieldPack';
	}

	if(Instigator.Controller != None && Instigator.Controller.Adrenaline < Instigator.Controller.AdrenalineMax)
		Potentials[Potentials.Length] = class'AdrenalinePickup';

	if(FRand() < UDamageChanceBonus * float(Modifier))
		Potentials[Potentials.Length] = class'UDamagePack';
	
	Count = 0;
	for(Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if (W != None)
		{
			if(W.NeedAmmo(0))
			{
				AmmoPickupClass = W.AmmoPickupClass(0);
				if (AmmoPickupClass != None)
					Potentials[Potentials.Length] = AmmoPickupClass;
			}
			else if(W.NeedAmmo(1))
			{
				AmmoPickupClass = W.AmmoPickupClass(1);
				if (AmmoPickupClass != None)
					Potentials[Potentials.Length] = AmmoPickupClass;
			}
		}

		if(++Count > 1000)
			break;
	}

	if(Potentials.Length > 0)
		return Potentials[Rand(Potentials.Length)];
	else
		return None;
}

simulated function BuildDescription()
{
	Super.BuildDescription();
    
    if(Modifier >= 0) {
        AddToDescription(LuckText);
    } else {
        AddToDescription(MisfortuneText);
    }
}

defaultproperties {
    LuckText="spawns pickups nearby"
	MisfortuneText="destroys nearby pickups"
	DamageBonus=0.03
	UDamageChanceBonus=0.015
	MinModifier=-5
	MaxModifier=7
    bCanHaveZeroModifier=False
	ModifierOverlay=FinalBlend'MutantSkins.Shaders.MutantGlowFinal'
	PatternPos="Lucky $W"
	PatternNeg="$W of Misfortune"
	//AI
	AIRatingBonus=0.025
}

