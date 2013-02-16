class WeaponModifier_Poison extends RPGWeaponModifier;

var RPGRules RPGRules;

var localized string PoisonText, PoisonAbsText;

var config int PoisonLifespan;
var config int PoisonMode; //0 = PM_Absolute, 1 = PM_Percentage, 2 = PM_Curve

var config float BasePercentage;
var config float Curve;

var config int AbsDrainPerLevel;
var config float PercDrainPerLevel;

var config int MinHealth; //cannot drain below this

replication {
    reliable if(Role == ROLE_Authority)
		ClientReceivePoisonConfig;
}

function SendConfig() {
    Super.SendConfig();
    ClientReceivePoisonConfig(PoisonMode, AbsDrainPerLevel);
}

simulated function ClientReceivePoisonConfig(int a, int b) {
    if(Role < ROLE_Authority) {
        PoisonMode = a;
        AbsDrainPerLevel = b;
    }
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Effect_Poison Poison;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

	Identify();

	Poison = Effect_Poison(class'Effect_Poison'.static.Create(Injured, InstigatedBy.Controller, PoisonLifespan, Modifier));
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

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(PoisonText);
    
    if(EPoisonMode(PoisonMode) == PM_Absolute) {
        AddToDescription(Repl(PoisonAbsText, "$1", Modifier * AbsDrainPerLevel));
    }
}

defaultproperties
{
	PoisonText="poisons targets"
	PoisonAbsText="$1 health/s"
	PoisonLifespan=5
	MinModifier=1
	MaxModifier=5
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.LinkHit'
	PatternPos="Poisonous $W"
	PoisonMode=PM_Curve
	
    BasePercentage=0.05
    Curve=1.25
	AbsDrainPerLevel=2
	PercDrainPerLevel=0.10
	MinHealth=10
	//AI
	AIRatingBonus=0.075
}
