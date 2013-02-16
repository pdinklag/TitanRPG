class WeaponModifier_Vorpal extends RPGWeaponModifier;

var localized string VorpalText;

replication {
    reliable if(Role == ROLE_Authority)
		ClientReceiveVorpalConfig;
}

function SendConfig() {
    Super.SendConfig();
    ClientReceiveVorpalConfig(MinModifier);
}

simulated function ClientReceiveVorpalConfig(int a) {
    if(Role < ROLE_Authority) {
        MinModifier = a;
    }
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
	local RPGEffect Vorpal;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

	if(Damage > 0 && Rand(99) <= (Modifier - MinModifier))
	{
		Identify();
	
		Vorpal = class'Effect_Vorpal'.static.Create(Injured, InstigatedBy.Controller);
		if(Vorpal != None)
			Vorpal.Start();
	}
}

simulated function BuildDescription() {
	Super.BuildDescription();
 
    AddToDescription(Repl(VorpalText, "$1",
        class'Util'.static.FormatPercent(0.01f * float(Modifier + 1 - MinModifier))));
}

defaultproperties
{
	VorpalText="$1 instant kill chance"
	DamageBonus=0.10
	MinModifier=6
	MaxModifier=10
	ModifierOverlay=Shader'XGameShaders.BRShaders.BombIconYS'
	PatternPos="Vorpal $W"
	ForbiddenWeaponTypes(0)=Class'XWeapons.AssaultRifle'
	ForbiddenWeaponTypes(1)=Class'XWeapons.FlakCannon'
	ForbiddenWeaponTypes(2)=Class'XWeapons.LinkGun'
	ForbiddenWeaponTypes(3)=Class'XWeapons.Minigun'
	//AI
	AIRatingBonus=0.10
}
