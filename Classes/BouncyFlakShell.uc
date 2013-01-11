class BouncyFlakShell extends FlakShell;

simulated event HitWall(vector HitNormal, actor Wall)
{
	if(!class'WeaponModifier_Bounce'.static.Bounce(Self, HitNormal, Wall))
		Super.HitWall(HitNormal, Wall);
}

defaultproperties
{
	bBounce=True
	Buoyancy=0.75 //abused as bounciness
	LifeSpan=10.00
}
