class TitanPlayerController extends XPlayer;

//Fixed GetWeapon function to work with RPGWeapons as well!
exec function GetWeapon(class<Weapon> NewWeaponClass )
{
	local Weapon W;
    local Inventory Inv;
    local int Count;

    if ( (Pawn == None) || (Pawn.Inventory == None) || (NewWeaponClass == None) )
        return;
	
    if ( Pawn.PendingWeapon != None && Pawn.PendingWeapon.bForceSwitch )
        return;

    for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
    {
		W = class'Util'.static.GetWeapon(Inv);	

        if ( W != None && ClassIsChildOf(W.class, NewWeaponClass) && Inv != Pawn.Weapon )
        {
            Pawn.PendingWeapon = Weapon(Inv); //NOT W, which could be the ModifiedWeapon of an RPGWeapon
            if ( !Pawn.PendingWeapon.HasAmmo() )
            {
                ClientMessage(Pawn.PendingWeapon.ItemName $ Pawn.PendingWeapon.MessageNoAmmo );
                Pawn.PendingWeapon = None;
                return;
            }
            Pawn.Weapon.PutDown();
            return;
        }
		Count++;
		if ( Count > 1000 )
			return;
    }
}

//Allowing jump/crouch for up/down flying control!
state PlayerFlying
{
ignores SeePlayer, HearNoise, Bump;

	//copied from PlayerSwimming, updated
    function PlayerMove(float DeltaTime)
    {
        local rotator oldRotation;
        local vector X,Y,Z, NewAccel;

        GetAxes(Rotation, X, Y, Z);

        NewAccel = aForward * X + aStrafe * Y + aUp*vect(0,0,1);
		
        if ( VSize(NewAccel) < 1.0 )
            NewAccel = vect(0,0,0);

        // Update rotation.
        oldRotation = Rotation;
        UpdateRotation(DeltaTime, 2);

        if ( Role < ROLE_Authority ) // then save this move and replicate it
            ReplicateMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
        else
            ProcessMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
    }
}

// === FIXING SLOW MOUSE MOVEMENT WHILE USING MAGNET ===
// Player movement.
// Player walking on walls
state PlayerSpidering
{
ignores SeePlayer, HearNoise, Bump;

    // if spider mode, update rotation based on floor
    function UpdateRotation(float DeltaTime, float maxPitch)
    {
        local rotator ViewRotation;
        local vector MyFloor, CrossDir, FwdDir, OldFwdDir, OldX, RealFloor;

        if ( bInterpolating || Pawn.bInterpolating )
        {
            ViewShake(deltaTime);
            return;
        }

        TurnTarget = None;
        bRotateToDesired = false;
        bSetTurnRot = false;

        if ( (Pawn.Base == None) || (Pawn.Floor == vect(0,0,0)) )
            MyFloor = vect(0,0,1);
        else
            MyFloor = Pawn.Floor;

        if ( MyFloor != OldFloor )
        {
            // smoothly change floor
            RealFloor = MyFloor;
            MyFloor = Normal(6*DeltaTime * MyFloor + (1 - 6*DeltaTime) * OldFloor);
            if ( (RealFloor Dot MyFloor) > 0.999 )
                MyFloor = RealFloor;
			else
			{
				// translate view direction
				CrossDir = Normal(RealFloor Cross OldFloor);
				FwdDir = CrossDir Cross MyFloor;
				OldFwdDir = CrossDir Cross OldFloor;
				ViewX = MyFloor * (OldFloor Dot ViewX)
							+ CrossDir * (CrossDir Dot ViewX)
							+ FwdDir * (OldFwdDir Dot ViewX);
				ViewX = Normal(ViewX);

				ViewZ = MyFloor * (OldFloor Dot ViewZ)
							+ CrossDir * (CrossDir Dot ViewZ)
							+ FwdDir * (OldFwdDir Dot ViewZ);
				ViewZ = Normal(ViewZ);
				OldFloor = MyFloor;
				ViewY = Normal(MyFloor Cross ViewX);
			}
        }

		//aTurn - Mouse X Axis difference
		//aLookUp - Mouse Y Axis difference
		
        if ( (aTurn != 0) || (aLookUp != 0) )
        {
            // adjust Yaw based on aTurn
            if ( aTurn != 0 )
            	//corrects the mouse speed -pd
                ViewX = Normal(ViewX + 5 * ViewY * Sin(0.0005*DeltaTime*aTurn));

            // adjust Pitch based on aLookUp
            if ( aLookUp != 0 )
            {
                OldX = ViewX;
                //corrects the mouse speed -pd
                ViewX = Normal(ViewX + 5 * ViewZ * Sin(0.0005*DeltaTime*aLookUp));
                ViewZ = Normal(ViewX Cross ViewY);

                // bound max pitch
                if ( (ViewZ Dot MyFloor) < 0.707   )
                {
                    OldX = Normal(OldX - MyFloor * (MyFloor Dot OldX));
                    if ( (ViewX Dot MyFloor) > 0)
                        ViewX = Normal(OldX + MyFloor);
                    else
                        ViewX = Normal(OldX - MyFloor);

                    ViewZ = Normal(ViewX Cross ViewY);
                }
            }

            // calculate new Y axis
            ViewY = Normal(MyFloor Cross ViewX);
        }
		
        ViewRotation =  OrthoRotation(ViewX,ViewY,ViewZ);
        SetRotation(ViewRotation);
        ViewShake(deltaTime);
        ViewFlash(deltaTime);
        Pawn.FaceRotation(ViewRotation, deltaTime );
    }
}

function SendMessage(PlayerReplicationInfo Recipient, name MessageType, byte MessageID, float Wait, name BroadcastType)
{
	if(MessageType == 'FRIENDLYFIRE')
	{
		//Check if Recipient is currently holding a Healing gun.
		if(
			Controller(Recipient.Owner).Pawn != None && 
			WeaponHealer(Controller(Recipient.Owner).Pawn.Weapon) != None)
		{
			return; //Shut up.
		}
	}

	Super.SendMessage(Recipient, MessageType, MessageID, Wait, BroadcastType);
}

defaultproperties
{
}
