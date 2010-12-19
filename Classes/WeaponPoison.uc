class WeaponPoison extends RPGWeapon
	HideDropDown
	CacheExempt
	DependsOn(PoisonInv);

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
	RPGRules = class'RPGRules'.static.Find(Level.Game);
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local PoisonInv Inv;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(Victim == None || WeaponMagicNullifier(Victim.Weapon) != None)
		return;
		
	if(Victim != Instigator && Instigator.Controller.SameTeamAs(Victim.Controller))
		return;

	Identify();

	Inv = PoisonInv(Victim.FindInventoryType(class'PoisonInv'));
	if(Inv == None)
	{	
		Inv = Spawn(class'PoisonInv', Victim);
		Inv.Modifier = Modifier;
		Inv.PoisonMode = EPoisonMode(PoisonMode);
		Inv.BasePercentage = BasePercentage;
		Inv.Curve = Curve;
		Inv.AbsDrainPerLevel = AbsDrainPerLevel;
		Inv.PercDrainPerLevel = PercDrainPerLevel;
		Inv.MinHealth = MinHealth;
		
		Inv.LifeSpan = PoisonLifespan;
		Inv.RPGRules = RPGRules;
		Inv.GiveTo(Victim);
	}
	else
	{
		Inv.Modifier = Modifier;
		Inv.LifeSpan = PoisonLifespan;
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
