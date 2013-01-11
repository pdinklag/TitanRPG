class BouncyRocket extends RPGRocketProj;

simulated event HitWall(vector HitNormal, actor Wall)
{
	if(!class'WeaponModifier_Bounce'.static.Bounce(Self, HitNormal, Wall))
		Super.HitWall(HitNormal, Wall);
}

defaultproperties
{
	Buoyancy=1.00 //abused as bounciness
	LifeSpan=13.33
}
