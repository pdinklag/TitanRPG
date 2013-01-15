class WeaponModifier_Feather extends RPGWeaponModifier;

var float JumpZModifier, MaxFallSpeedModifier;

var config float MaxFallSpeedBonus;

var localized string FeatherText, FallDamageText;

replication {
    reliable if(Role == ROLE_Authority)
		ClientReceiveFeatherConfig;
}

function SendConfig() {
    Super.SendConfig();
    ClientReceiveFeatherConfig(MaxFallSpeedBonus);
}

simulated function ClientReceiveFeatherConfig(float a) {
    if(Role < ROLE_Authority) {
        MaxFallSpeedBonus = a;
    }
}

function StartEffect()
{
	Identify();

	JumpZModifier = 1.f + BonusPerLevel * Abs(float(Modifier));
	if(Modifier < 0 && JumpZModifier != 0)
		JumpZModifier = 1.0 / JumpZModifier;
	
	MaxFallSpeedModifier = 1.f + MaxFallSpeedBonus * Abs(float(Modifier));
	if(Modifier < 0 && MaxFallSpeedModifier != 0)
		MaxFallSpeedModifier = 1.0 / MaxFallSpeedModifier;
	
	Instigator.JumpZ *= JumpZModifier;
	Instigator.MaxFallSpeed *= MaxFallSpeedModifier;
}

function StopEffect()
{
	if(JumpZModifier != 0)
		Instigator.JumpZ /= JumpZModifier;
		
	if(MaxFallSpeedModifier != 0)
		Instigator.MaxFallSpeed /= MaxFallSpeedModifier;
	
	JumpZModifier = 0;
	MaxFallSpeedModifier = 0;
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(FeatherText, BonusPerLevel);
	AddToDescription(FallDamageText, MaxFallSpeedBonus);
}

defaultproperties
{
	FeatherText="$1 jump height"
	FallDamageText="$1 soft landing"
	DamageBonus=0.040000
	BonusPerLevel=0.050000
	MaxFallSpeedBonus=0.030000
	MinModifier=-3
	MaxModifier=10
    bCanHaveZeroModifier=False
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconBS'
	PatternPos="$W of Feather"
	PatternNeg="$W of Burden"
	//AI
	AIRatingBonus=0.000000
}
