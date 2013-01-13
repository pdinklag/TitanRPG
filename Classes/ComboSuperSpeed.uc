class ComboSuperSpeed extends Combo
	config(TitanRPG);
	
var xEmitter LeftTrail, RightTrail;
var config float SpeedBonus, JumpZBonus;

function StartEffect(xPawn P)
{
    LeftTrail = Spawn(class'FX_SuperSpeedTrail', P,, P.Location, P.Rotation);
    P.AttachToBone(LeftTrail, 'lfoot');

    RightTrail = Spawn(class'FX_SuperSpeedTrail', P,, P.Location, P.Rotation);
    P.AttachToBone(RightTrail, 'rfoot');
	
	P.AirControl  *= (1.0 + SpeedBonus);
	P.GroundSpeed *= (1.0 + SpeedBonus);
	P.WaterSpeed  *= (1.0 + SpeedBonus);
	P.AirSpeed    *= (1.0 + SpeedBonus);
	P.JumpZ       *= (1.0 + JumpZBonus);
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
	P.JumpZ       /= (1.0 + JumpZBonus);
}

defaultproperties
{
	SpeedBonus=0.6
	JumpZBonus=0.5 //original speed combo value
	Duration=16
    ExecMessage="Super Speed!"
    ComboAnnouncementName=Speed
    keys(0)=1
    keys(1)=1
    keys(2)=1
    keys(3)=1
}
