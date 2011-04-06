//I present to you: NULL VEHICLES!! they're evil... -pd
class VehicleMagicNullEntropy extends VehicleMagic;

function AdjustTargetDamage(out int Damage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if(Damage > 0 && Victim.IsA('Pawn'))
		class'EffectNullEntropy'.static.Apply(Pawn(Victim), Instigator.Controller, 5);
}

defaultproperties
{
	MagicName="Null Entropy"
	NameSuffix=" of Null Entropy"
	OverlayMat=Shader'MutantSkins.Shaders.MutantGlowShader'
}