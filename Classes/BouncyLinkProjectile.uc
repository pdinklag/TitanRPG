class BouncyLinkProjectile extends RPGLinkProjectile;

simulated event HitWall(vector HitNormal, actor Wall)
{
	if(!class'WeaponModifier_Bounce'.static.Bounce(Self, HitNormal, Wall))
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
