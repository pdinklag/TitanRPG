//Hack fix for Painter to fix some Accessed Nones
class RPGPainterFire extends PainterFire;

state Paint
{
	function Rotator AdjustAim(Vector Start, float InAimError)
	{
		if ( Bot(Instigator.Controller) != None )
		{
			Instigator.Controller.Focus = None;
			if ( bAlreadyMarked )
				Instigator.Controller.FocalPoint = MarkLocation;
			else
				Instigator.Controller.FocalPoint = Painter(Weapon).MarkLocation;
			return rotator(Instigator.Controller.FocalPoint - Start);
		}
		else
			return Global.AdjustAim(Start, InAimError);
	}

    function BeginState()
    {
        IonCannon = None;

        if (Weapon.Role == ROLE_Authority)
        {
            if (Beam == None)
            {
                Beam = Spawn(class'RPGPainterBeamEffect');
            }
            bInitialMark = true;
            bValidMark = false;
            MarkTime = Level.TimeSeconds;
            SetTimer(0.25, true);
        }

        ClientPlayForceFeedback(TAGFireForce);
    }
}

defaultproperties
{
}
