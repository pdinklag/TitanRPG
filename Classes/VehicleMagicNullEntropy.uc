//I present to you: NULL VEHICLES!! they're evil... -pd
class VehicleMagicNullEntropy extends VehicleMagic;

function AdjustTargetDamage(out int Damage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local RPGEffect Effect;

	if(Damage > 0 && Victim.IsA('Pawn'))
	{
		Effect = class'Effect_NullEntropy'.static.Create(Pawn(Victim), Instigator.Controller, 5);
		if(Effect != None)
			Effect.Start();
	}
}

defaultproperties
{
	MagicName="Null Entropy"
	NameSuffix=" of Null Entropy"
	OverlayMat=Shader'MutantSkins.Shaders.MutantGlowShader'
}