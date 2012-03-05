class WeaponModifier_Heal extends RPGWeaponModifier;

var config int MaxHealth;

var localized string HealText;

static function bool AllowedFor(class<Weapon> Weapon, optional Pawn Other)
{
	local int x;
	local class<ProjectileFire> ProjFire;
	
	if(!Super.AllowedFor(Weapon, Other))
		return false;
	
	//if it's a team game, always allowed
	if(Other.Level.Game.bTeamGame)
	{
		return true;
	}
	else
	{
		//otherwise only allowed on splash damage weapons
		for(x = 0; x < ArrayCount(Weapon.default.FireModeClass); x++)
		{
			if(!Weapon.default.FireModeClass[x].IsA('InstantFire'))
			{
				ProjFire = class<ProjectileFire>(Weapon.default.FireModeClass[x]);
				if(ProjFire == None || ProjFire.default.ProjectileClass == None || ProjFire.default.ProjectileClass.default.DamageRadius > 0)
				{
					return true;
				}
			}
		}
	}
	return false;
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Effect_Heal Heal;
	local int HealthGiven;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	
	HealthGiven = Max(1, OriginalDamage * (BonusPerLevel * float(Modifier)));

	Heal = Effect_Heal(class'Effect_Heal'.static.Create(Injured, Instigator.Controller,, GetMaxHealthBonus()));
	if(Heal != None)
	{
		Identify();
	
		Heal.HealAmount = HealthGiven;
		Heal.Start();
	}
	
	if(Injured == Instigator || Instigator.Controller.SameTeamAs(Injured.Controller))
	{
		Momentum = vect(0, 0, 0);
		Damage = 0;
	}
}

//function to be overridden in Meidc subclass
function int GetMaxHealthBonus()
{
	return MaxHealth;
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(HealText, BonusPerLevel);
}

defaultproperties
{
	HealText="$1 healing"
	BonusPerLevel=0.05
	MaxHealth=50
	MinModifier=1
	MaxModifier=6
	ModifierOverlay=Shader'TitanRPG.Overlays.BlueShader'
	PatternPos="Healing $W"
	//AI
	AIRatingBonus=0
}
