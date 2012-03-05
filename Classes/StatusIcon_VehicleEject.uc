class StatusIcon_VehicleEject extends RPGStatusIcon;

var AbilityVehicleEject EjectorSeat;

function Tick(float dt)
{
	EjectorSeat = AbilityVehicleEject(RPRI.GetAbility(class'AbilityVehicleEject'));
	bShouldTick = (EjectorSeat == None);
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
	bShouldTick=True
}
