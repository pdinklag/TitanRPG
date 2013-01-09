class WeaponModifier_Vorpal extends RPGWeaponModifier;

var int ReplicatedMinModifier;

var localized string VorpalText;

replication
{
	reliable if(Role == ROLE_Authority && bNetOwner)
		ReplicatedMinModifier; //needed for description
}

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();	
	ReplicatedMinModifier = MinModifier;
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
	local RPGEffect Vorpal;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);

	if(Damage > 0 && Rand(99) <= (Modifier - MinModifier))
	{
		Identify();
	
		Vorpal = class'Effect_Vorpal'.static.Create(Injured, Instigator.Controller);
		if(Vorpal != None)
			Vorpal.Start();
	}
}

simulated function BuildDescription() {
	Super.BuildDescription();
 
    AddToDescription(Repl(VorpalText, "$1",
        class'Util'.static.FormatPercent(0.01f * float(Modifier + 1 - ReplicatedMinModifier))));
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
