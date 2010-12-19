class VehicleMagicSpeed extends VehicleMagic;

function ModifyVehicle()
{
	class'Util'.static.AdjustVehicleSpeed(Vehicle(Instigator), 2.0f);
}

function UnModifyVehicle()
{
	class'Util'.static.SetVehicleSpeed(Vehicle(Instigator), 1.0f);
}

defaultproperties
{
	MagicName="Speed"
	NamePrefix=" of Hotwheels"
	OverlayMat=Shader'XGameShaders.BRShaders.BombIconBS'
}
