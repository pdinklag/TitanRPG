class RPGBouncyLinkProjectile extends RPGLinkProjectile;

simulated event HitWall(vector HitNormal, actor Wall)
{
	if(!class'WeaponBounce'.static.Bounce(Self, HitNormal, Wall))
		Super.HitWall(HitNormal, Wall);
}

simulated event Tick(float dt)
{
	Super.Tick(dt);
}

defaultproperties
{
	Buoyancy=1.00 //abused as bounciness
	LifeSpan=5
}
