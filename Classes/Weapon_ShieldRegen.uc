class Weapon_ShieldRegen extends RPGWeapon
	HideDropDown
	CacheExempt;

var config float RegenInterval;

var localized string ShieldText;

var int LastHealth, LastShield;

function StartEffect()
{
	SetRPGTimer(RegenInterval, true);
}

function StopEffect()
{
	SetRPGTimer(0, false);
}

function RPGTimer()
{
	local xPawn x;
	
	x = xPawn(Instigator);
	if(x != None)
	{
		if(x.Health >= LastHealth && x.ShieldStrength >= LastShield)
		{
			if(x.ShieldStrength < x.ShieldStrengthMax)
				x.ShieldStrength = FMin(x.ShieldStrength + float(Modifier) * BonusPerLevel, x.ShieldStrengthMax);
		}
		
		LastHealth = x.Health;
		LastShield = x.ShieldStrength;
	}
	else
	{
		LastHealth = 0;
		LastShield = 0;
	}
}

defaultproperties
{
	ShieldText="shield regeneration"
	PatternPos="$W of Shield"
	DamageBonus=0.04
	BonusPerLevel=1.00
	RegenInterval=2.00
	MinModifier=1
	MaxModifier=5
	//ModifierOverlay=TexEnvMap'TitanRPG.Overlays.goldenv' - for another weapon
	ModifierOverlay=TexEnvMap'PickupSkins.Shaders.TexEnvMap2'
	//AI
	AIRatingBonus=0.05
}
