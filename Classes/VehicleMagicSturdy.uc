class VehicleMagicSturdy extends VehicleMagic;

function AdjustPlayerDamage(out int Damage, Pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Momentum = vect(0, 0, 0);
}

defaultproperties
{
	MagicName="Sturdy"
	NamePrefix="Sturdy "
	OverlayMat=Shader'UT2004Weapons.Shaders.ShockHitShader'
}