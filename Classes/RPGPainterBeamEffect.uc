class RPGPainterBeamEffect extends PainterBeamEffect;

simulated function Tick(float dt)
{
    local Vector BeamDir;
    local Vector X,Y,Z;
    local xWeaponAttachment Attachment;

    if (Role == ROLE_Authority && (Instigator == None || Instigator.Controller == None))
    {
        Destroy();
        return;
    }

    if (Level.NetMode == NM_DedicatedServer)
    {
        StartEffect = Instigator.Location + Instigator.EyeHeight*Vect(0,0,1);
        return;
    }

    // set beam start location
    if ( Instigator == None )
    {
        SetLocation(StartEffect);
    }
    else
    {
        if ( Instigator.IsFirstPerson() && Instigator.Weapon != None )
        {
		if ( Instigator.Weapon.WeaponCentered() )
			SetLocation( Instigator.Location );
		else
		{
			Instigator.Weapon.GetViewAxes(X, Y, Z);
			SetLocation( (Instigator.Location + Instigator.CalcDrawOffset(Instigator.Weapon) + EffectOffset.X * X + Instigator.Weapon.Hand * EffectOffset.Y * Y + EffectOffset.Z * Z) );
		}

		if (Painter(Instigator.Weapon) != None)
			EndEffect = Painter(Instigator.Weapon).EndEffect;
		else if (RPGWeapon(Instigator.Weapon) != None && Painter(RPGWeapon(Instigator.Weapon).ModifiedWeapon) != None)
			EndEffect = Painter(RPGWeapon(Instigator.Weapon).ModifiedWeapon).EndEffect;
        }
        else
        {
            Attachment = xPawn(Instigator).WeaponAttachment;
            if (Attachment != None && (Level.TimeSeconds - Attachment.LastRenderTime) < 1)
                SetLocation( Attachment.GetTipLocation() );
            else
                SetLocation( Instigator.Location + Instigator.EyeHeight*Vect(0,0,1) + Normal(EndEffect - Instigator.Location) * 25.0 );
        }
        if (Role == ROLE_Authority) // what clients will use if their instigator is not relevant yet
            StartEffect = Location;
    }

    BeamDir = Normal(EndEffect - Location);
    SetRotation(Rotator(BeamDir));

    mSpawnVecA = EndEffect;

    if (Spot != None)
    {
        Spot.SetLocation(EndEffect - BeamDir*10.0);
    }

    if (TargetState == PTS_Marked)
    {
        if (Brightness == 40.0)
            PlaySound(MarkSound);
        SetBrightness( FMax(FMin(Brightness+dt*100.0, 250.0), 100.0) );
    }
    else
        SetBrightness( 40.0 );

    if (TargetState == PTS_Aquired)
        GotoState('Aquired');
    else if (TargetState == PTS_Cancelled)
        GotoState('Cancelled');
}

defaultproperties
{
}
