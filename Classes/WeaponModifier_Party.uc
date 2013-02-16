class WeaponModifier_Party extends RPGWeaponModifier;

var localized string DiscoText;

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
    local RPGEffect Effect;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
    
    if(Damage > 0) {
		Effect = class'Effect_Disco'.static.Create(
			Injured,
			InstigatedBy.Controller,
			BonusPerLevel * float(Modifier));
		
		if(Effect != None) {
			Effect.Start();
            Identify();
		}
	}
}

simulated function BuildDescription() {
	Super.BuildDescription();
	AddToDescription(Repl(DiscoText, "$1", class'Util'.static.FormatFloat(BonusPerLevel * Modifier)));
}

defaultproperties {
    DiscoText="causes disco mode for $1s"
	DamageBonus=0
    BonusPerLevel=0.25
	MinModifier=1
	MaxModifier=10
	//ModifierOverlay=FinalBlend'TitanRPG.Disco.IonSphereFinal'
	ModifierOverlay=Combiner'TitanRPG.Overlays.DiscoCombiner'
	PatternPos="Party $W"
	//AI
	AIRatingBonus=0.0125
}
