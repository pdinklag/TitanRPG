class TurretKnockoutInv extends Inventory;

var float SightRadius;

function Start(float Modifier)
{
	Modifier *= 0.5f;

	SightRadius = Instigator.SightRadius;
	Instigator.SightRadius = 0;
	
	SetTimer(Modifier, false);
	
	class'Util'.static.SetVehicleOverlay(
		ASTurret(Instigator),
		class'WeaponKnockback'.default.OverlayMaterial,
		Modifier,
		true);
}

event Destroyed()
{
	if(Instigator != None)
		Instigator.SightRadius = SightRadius;
}

function Timer()
{
	Destroy();
}

defaultproperties
{
}
