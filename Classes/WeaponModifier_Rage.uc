class WeaponModifier_Rage extends RPGWeaponModifier;

var config float DamageReturn;
var config int MinimumHealth;

var localized string RageText;

replication {
    reliable if(Role == ROLE_Authority)
		ClientReceiveRageConfig;
}

function SendConfig() {
    Super.SendConfig();
    ClientReceiveRageConfig(DamageReturn, MinimumHealth);
}

simulated function ClientReceiveRageConfig(float a, int b) {
    if(Role < ROLE_Authority) {
        DamageReturn = a;
        MinimumHealth = b;
    }
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    local int localDamage;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

	Identify();
	if(Damage > 0)
	{
		localDamage = int(FMax(1.0, DamageReturn * float(Damage)));

		if(localDamage >= Instigator.Health - MinimumHealth)
		{
			localDamage = Instigator.Health - MinimumHealth;
		}
		
		if(localDamage > 0 && (InstigatedBy.Controller == None || !InstigatedBy.Controller.bGodMode))
			Instigator.Health = Max(1, Instigator.Health - localDamage); //make sure you can never reach 0, as that causes evil bugs
	}
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(Repl(RageText, "$2", MinimumHealth), DamageReturn);
}

defaultproperties
{
	RageText="$1 self-damage down to $2"
	DamageBonus=0.10
	DamageReturn=0.10
	MinimumHealth=70
	MinModifier=6
	MaxModifier=10
	ModifierOverlay=Combiner'EpicParticles.Shaders.Combiner3'
	PatternPos="$W of Rage"
	ForbiddenWeaponTypes(0)=Class'XWeapons.LinkGun'
	ForbiddenWeaponTypes(1)=Class'XWeapons.Minigun'
	ForbiddenWeaponTypes(2)=Class'XWeapons.AssaultRifle'
	ForbiddenWeaponTypes(3)=Class'XWeapons.ShieldGun'
	ForbiddenWeaponTypes(4)=Class'XWeapons.TransLauncher'
	//AI
	AIRatingBonus=0.075
}
