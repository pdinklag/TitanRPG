class RPGClassicSniperRifle extends ClassicSniperRifle
	HideDropDown
	CacheExempt;

//client-side for stealth
var float BarCharge;

simulated function float ChargeBar() {
    return BarCharge;
}

defaultproperties {
    PickupClass=class'RPGClassicSniperRiflePickup'
}
