class WeaponHealer extends RPGWeapon
	HideDropDown
	CacheExempt;

var RPGRules rules;

var config int MaxHealth;

var localized string HealText;

replication
{
	reliable if(bNetOwner && Role == ROLE_Authority)
		MaxHealth;
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	local class<ProjectileFire> ProjFire;
	
	if(!Super.AllowedFor(Weapon, Other))
		return false;
	
	// if it's a team game, always allowed (no matter what it is player can use it to heal teammates)
	if (Other.Level.Game.bTeamGame)
	{
		return true;
	}
	else
	{
		//otherwise only allowed on splash damage weapons
		for (x = 0; x < NUM_FIRE_MODES; x++)
		{
			if(!Weapon.default.FireModeClass[x].IsA('InstantFire'))
			{
				ProjFire = class<ProjectileFire>(Weapon.default.FireModeClass[x]);
				if (ProjFire == None || ProjFire.default.ProjectileClass == None || ProjFire.default.ProjectileClass.default.DamageRadius > 0)
				{
					return true;
				}
			}
		}
	}

	return false;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Effect_Heal Heal;
	local int HealthGiven;
	
	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	
	if(Victim != None && OriginalDamage > 0)
	{
		HealthGiven = Max(1, OriginalDamage * (BonusPerLevel * float(Modifier)));
	
		Heal = Effect_Heal(class'Effect_Heal'.static.Create(Victim, Instigator.Controller,, GetMaxHealthBonus()));
		if(Heal != None)
		{
			Identify();
		
			Heal.HealAmount = HealthGiven;
			Heal.Start();
		}
		
		if(Victim == Instigator || Instigator.Controller.SameTeamAs(Victim.Controller))
		{
			Momentum = vect(0, 0, 0);
			Damage = 0;
		}
	}
}

//function that can be overridden in subclass.
function int GetMaxHealthBonus()
{
	return MaxHealth;
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(HealText, "$1", GetBonusPercentageString(BonusPerLevel));
	return text;
}

defaultproperties
{
	HealText="$1 healing"
	BonusPerLevel=0.050000
	MaxHealth=50
	MinModifier=1
	MaxModifier=6
	ModifierOverlay=Shader'<? echo($packageName); ?>.Overlays.BlueShader'
	PatternPos="Healing $W"
	//AI
	AIRatingBonus=0.000000
}
