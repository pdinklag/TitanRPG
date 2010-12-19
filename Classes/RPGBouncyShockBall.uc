class RPGBouncyShockBall extends ShockProjectile;

simulated event HitWall(vector HitNormal, actor Wall)
{
	if(!class'WeaponBounce'.static.Bounce(Self, HitNormal, Wall))
		Super.HitWall(HitNormal, Wall);
}

defaultproperties
{
	Buoyancy=1.00 //abused as bounciness
	LifeSpan=16.67
}
