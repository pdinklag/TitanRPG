class Ability_AmmoRegen extends RPGAbility;

var config float RegenInterval;
var config int MinRegenPerLevel;

var MutTitanRPG RPGMut; //to avoid the nasty accessed none's at the end of a match

replication
{
	reliable if(Role == ROLE_Authority)
		RegenInterval, MinRegenPerLevel;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	RPGMut = class'MutTitanRPG'.static.Instance(Level);
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);
	SetTimer(RegenInterval, true);
}

function int GetRegenAmountFor(class<Ammunition> AmmoClass)
{
	return Max(MinRegenPerLevel * AbilityLevel, int(
		BonusPerLevel * float(AbilityLevel) * float(AmmoClass.default.MaxAmmo)));
}

function Timer()
{
	local Inventory Inv;
	local Ammunition Ammo;
	local Weapon W;

	if(Instigator == None || Instigator.Health <= 0)
	{
		SetTimer(0.0f, false);
		return;
	}	
	
	for(Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if(W != None)
		{
			if(W.bNoAmmoInstances && W.AmmoClass[0] != None && !RPGMut.IsSuperWeaponAmmo(W.AmmoClass[0]))
			{
				W.AddAmmo(GetRegenAmountFor(W.AmmoClass[0]), 0);
				if(W.AmmoClass[0] != W.AmmoClass[1] && W.AmmoClass[1] != None)
					W.AddAmmo(GetRegenAmountFor(W.AmmoClass[1]), 1);
			}
		}
		else
		{
			Ammo = Ammunition(Inv);
			if(Ammo != None && !RPGMut.IsSuperWeaponAmmo(Ammo.Class))
				Ammo.AddAmmo(GetRegenAmountFor(Ammo.class));
		}
	}
}

simulated function string DescriptionText()
{
	return Repl(
				Repl(
					Repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
					"$2", MinRegenPerLevel),
				"$3", class'Util'.static.FormatFloat(RegenInterval));
}

defaultproperties
{
	BonusPerLevel=0.010000
	RegenInterval=3.000000
	MinRegenPerLevel=1
	
	AbilityName="Resupply"
	Description="Adds $1 of the max ammo (or at least $2) per level to each ammo type you own every $3 seconds.|Does not give ammo to superweapons or the translocator."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=7
	Category=class'AbilityCategory_Weapons'
}
