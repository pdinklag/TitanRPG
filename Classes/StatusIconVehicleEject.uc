class StatusIconVehicleEject extends RPGStatusIcon;

var AbilityVehicleEject EjectorSeat;

//Client
var float NextVehicleTime;

simulated function ClientInitialize()
{
	EjectorSeat = AbilityVehicleEject(RPRI.GetAbility(class'AbilityVehicleEject'));
	EjectorSeat.Status = Self;
}

simulated function bool IsVisible()
{
	return (
		EjectorSeat != None &&
		EjectorSeat.AbilityLevel >= 0 &&
		NextVehicleTime > Level.TimeSeconds
	);
}

simulated function string GetText()
{
	return string(1 + int(NextVehicleTime - Level.TimeSeconds));
}

defaultproperties
{
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Eject'
}
