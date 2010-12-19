class ComboSuperSpeed extends Combo
	config(TitanRPG);
	
var xEmitter LeftTrail, RightTrail;
var config float SpeedBonus;

function StartEffect(xPawn P)
{
    LeftTrail = Spawn(class'SuperSpeedTrail', P,, P.Location, P.Rotation);
    P.AttachToBone(LeftTrail, 'lfoot');

    RightTrail = Spawn(class'SuperSpeedTrail', P,, P.Location, P.Rotation);
    P.AttachToBone(RightTrail, 'rfoot');
	
	P.AirControl  *= (1.0 + SpeedBonus);
	P.GroundSpeed *= (1.0 + SpeedBonus);
	P.WaterSpeed  *= (1.0 + SpeedBonus);
	P.AirSpeed    *= (1.0 + SpeedBonus);
	P.JumpZ       *= (1.0 + 1.25 * SpeedBonus);
}

function StopEffect(xPawn P)
{
	if (LeftTrail != None)
		LeftTrail.Destroy();

	if (RightTrail != None)
		RightTrail.Destroy();

	// Our replacement: the opposite of what happens in ComboSpeed.StartEffect().
	P.AirControl  /= (1.0 + SpeedBonus);
	P.GroundSpeed /= (1.0 + SpeedBonus);
	P.WaterSpeed  /= (1.0 + SpeedBonus);
	P.AirSpeed    /= (1.0 + SpeedBonus);
	P.JumpZ       /= (1.0 + 1.25 * SpeedBonus);
}

defaultproperties
{
	SpeedBonus=0.533333 //+33%
	Duration=16
    ExecMessage="Super Speed!"
    ComboAnnouncementName=Speed
    keys(0)=1
    keys(1)=1
    keys(2)=1
    keys(3)=1
}
