class WeaponModifier_Freeze extends RPGWeaponModifier;

var config float FreezeMax, FreezeDuration;

var localized string FreezeText;

replication {
    reliable if(Role == ROLE_Authority)
		ClientReceiveFreezeConfig;
}

function SendConfig() {
    Super.SendConfig();
    ClientReceiveFreezeConfig(FreezeMax, FreezeDuration);
}

simulated function ClientReceiveFreezeConfig(float a, float b) {
    if(Role < ROLE_Authority) {
        FreezeMax = a;
        FreezeDuration = b;
    }
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local RPGEffect Effect;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

	if(Damage > 0)
	{
		Effect = class'Effect_Freeze'.static.Create(
			Injured,
			InstigatedBy.Controller,
			Modifier * FreezeDuration,
			1.0f - FMin(BonusPerLevel * Modifier, FreezeMax));
		
		if(Effect != None)
		{
			Identify();
			Effect.Start();
		}
	}
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(FreezeText, FMin(BonusPerLevel, FreezeMax / float(Modifier)));
}

defaultproperties
{
	BonusPerLevel=0.15
	FreezeMax=0.90
	FreezeDuration=0.50
	FreezeText="slows targets down $1"
	DamageBonus=0.05
	MinModifier=4
	MaxModifier=6
	ModifierOverlay=Shader'TitanRPG.Overlays.GreyShader'
	PatternPos="Freezing $W"
	//AI
	AIRatingBonus=0.05
}
