class WeaponModifier_Rage extends RPGWeaponModifier;

var config float DamageReturn;
var config int MinimumHealth;

var localized string RageText;

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    local int localDamage;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);

	Identify();
	if(Damage > 0)
	{
		localDamage = int(FMax(1.0, DamageReturn * float(Damage)));

		if(localDamage >= Instigator.Health - MinimumHealth)
		{
			localDamage = Instigator.Health - MinimumHealth;
		}
		
		if(localDamage > 0 && (Instigator.Controller == None || !Instigator.Controller.bGodMode))
			Instigator.Health = Max(1, Instigator.Health - localDamage); //make sure you can never reach 0, as that causes evil bugs
	}
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(RageText);
}

defaultproperties
{
	RageText="self-damage"
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
