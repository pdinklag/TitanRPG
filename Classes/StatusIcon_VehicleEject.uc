class StatusIcon_VehicleEject extends RPGStatusIcon;

var AbilityVehicleEject EjectorSeat;

function Initialize()
{
	EjectorSeat = AbilityVehicleEject(RPRI.GetAbility(class'AbilityVehicleEject'));
}

function bool IsVisible()
{
	return (
		EjectorSeat != None &&
		EjectorSeat.AbilityLevel >= 0 &&
		EjectorSeat.NextVehicleTime > EjectorSeat.Level.TimeSeconds
	);
}

function string GetText()
{
	return string(1 + int(EjectorSeat.NextVehicleTime - EjectorSeat.Level.TimeSeconds));
}

defaultproperties
{
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Eject'
}
