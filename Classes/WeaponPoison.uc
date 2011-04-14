class WeaponPoison extends RPGWeapon
	HideDropDown
	CacheExempt;

var RPGRules RPGRules;

var localized string PoisonText;

var config int PoisonLifespan;
var config int PoisonMode; //0 = PM_Absolute, 1 = PM_Percentage, 2 = PM_Curve

var config float BasePercentage;
var config float Curve;

var config int AbsDrainPerLevel;
var config float PercDrainPerLevel;

var config int MinHealth; //cannot drain below this

function PostBeginPlay()
{
	Super.PostBeginPlay();
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local Effect_Poison Poison;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	Identify();

	Poison = Effect_Poison(class'Effect_Poison'.static.Create(Victim, Instigator.Controller, PoisonLifespan, Modifier));
	if(Poison != None)
	{
		Poison.PoisonMode = EPoisonMode(PoisonMode);
		Poison.BasePercentage = BasePercentage;
		Poison.Curve = Curve;
		Poison.AbsDrainPerLevel = AbsDrainPerLevel;
		Poison.PercDrainPerLevel = PercDrainPerLevel;
		Poison.MinHealth = MinHealth;
		Poison.Start();
	}
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= PoisonText;
	return text;
}

defaultproperties
{
	//bAddToOldWeapons=False
	PoisonText="poisons targets"
	PoisonLifespan=5
	MinModifier=1
	MaxModifier=5
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.LinkHit'
	PatternPos="Poisonous $W"
	PoisonMode=PM_Curve
	
    BasePercentage=0.050000
    Curve=1.250000
	AbsDrainPerLevel=2
	PercDrainPerLevel=0.100000
	MinHealth=10
	//AI
	AIRatingBonus=0.075000
}
