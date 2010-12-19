class RPGBallLauncher extends BallLauncher
	HideDropDown
	CacheExempt;
	
var Weapon RestoreWeapon; //for Denial 3

simulated function BringUp(optional Weapon PrevWeapon)
{
	if(Role == ROLE_Authority)
		RestoreWeapon = PrevWeapon;

    Super.BringUp(PrevWeapon);
}

defaultproperties
{
}
