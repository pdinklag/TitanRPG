class RPGComboSpeed extends ComboSpeed
	config(TitanRPG);
	
function StartEffect(xPawn P)
{
	local RPGPlayerReplicationInfo RPRI;
	local class<xEmitter> EmitterClass;
	local Ability_Speed SpeedAbility;
	
	EmitterClass = class'SpeedTrail';

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(P.Controller);
	if(RPRI != None)
	{
		SpeedAbility = Ability_Speed(RPRI.GetOwnedAbility(class'Ability_Speed'));
		
		//Colored trail
		if(SpeedAbility != None && SpeedAbility.ShouldColorSpeedTrail())
			EmitterClass = class'FX_SuperSpeedTrail';
	}
	
    LeftTrail = Spawn(EmitterClass, P,, P.Location, P.Rotation);
    P.AttachToBone(LeftTrail, 'lfoot');

    RightTrail = Spawn(EmitterClass, P,, P.Location, P.Rotation);
    P.AttachToBone(RightTrail, 'rfoot');

    P.AirControl *= 1.4;
    P.GroundSpeed *= 1.4;
    P.WaterSpeed *= 1.4;
    P.AirSpeed *= 1.4;
    P.JumpZ *= 1.5;
}

function StopEffect(xPawn P)
{
	if (LeftTrail != None)
		LeftTrail.Destroy();

	if (RightTrail != None)
		RightTrail.Destroy();

	// Our replacement: the opposite of what happens in ComboSpeed.StartEffect().
	P.AirControl  /= 1.4;
	P.GroundSpeed /= 1.4;
	P.WaterSpeed  /= 1.4;
	P.AirSpeed    /= 1.4;
	P.JumpZ       /= 1.5;
}

defaultproperties
{
}
