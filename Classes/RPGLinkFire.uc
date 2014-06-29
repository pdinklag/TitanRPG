//=============================================================================
// TitanLinkFire
// Copyright 2007 by Jrubzjeknf <rrvanolst@hotmail.com>
//
// Fixes the clientside infinite loop crash.
//=============================================================================

class RPGLinkFire extends LinkFire;

event ModeDoFire()
{
	//TAM support
    if(Level.Game != None && Level.Game.IsA('Team_GameBase') && !LinkGun(Weapon).Linking)
		class'Util'.static.IncreaseTAMWeaponFireStats(Weapon.Instigator.PlayerReplicationInfo, "Link", "Secondary");

    Super.ModeDoFire();
}

//=============================================================================
// ModeTick
//
// Copy from LinkFire.ModeTick. Enables special handling when linking Pawns -pd
//=============================================================================

simulated function ModeTick(float dt)
{
	local Vector StartTrace, EndTrace, V, X, Y, Z;
	local Vector HitLocation, HitNormal, EndEffect;
	local Actor Other;
	local Rotator Aim;
	local RPGLinkGun LinkGun;
	local float Step, ls;
	local bot B;
	local bool bShouldStop, bIsHealingObjective;
	local int AdjustedDamage, OldHealth;
	local LinkBeamEffect LB;
	local DestroyableObjective HealObjective;
    local RPGGameObjectiveObserver Observer;
	local Vehicle LinkedVehicle;
    local RPGWeaponModifier WM;

    if ( !bIsFiring )
    {
		bInitAimError = true;
        return;
    }

    LinkGun = RPGLinkGun(Weapon);

    if ( LinkGun.Links < 0 )
        LinkGun.Links = 0;

    ls = LinkScale[Min(LinkGun.Links,5)];

    if ( myHasAmmo(LinkGun) && ((UpTime > 0.0) || (Instigator.Role < ROLE_Authority)) )
    {
        UpTime -= dt;

		// the to-hit trace always starts right in front of the eye
		LinkGun.GetViewAxes(X, Y, Z);
		StartTrace = GetFireStart( X, Y, Z);
        TraceRange = default.TraceRange + LinkGun.Links*250;

        if ( Instigator.Role < ROLE_Authority )
        {
			if ( Beam == None )
				ForEach Weapon.DynamicActors(class'LinkBeamEffect', LB )
					if ( !LB.bDeleteMe && (LB.Instigator != None) && (LB.Instigator == Instigator) )
					{
						Beam = LB;
						break;
					}

			if ( Beam != None )
				LockedPawn = Beam.LinkedPawn;
		}

        if ( LockedPawn != None )
			TraceRange *= 1.5;

        if ( Instigator.Role == ROLE_Authority )
		{
		    if ( bDoHit )
			    LinkGun.ConsumeAmmo(ThisModeNum, AmmoPerFire);

			B = Bot(Instigator.Controller);
			if ( (B != None) && (PlayerController(B.Squad.SquadLeader) != None) && (B.Squad.SquadLeader.Pawn != None) )
			{
				if ( IsLinkable(B.Squad.SquadLeader.Pawn)
					&& (B.Squad.SquadLeader.Pawn.Weapon != None && B.Squad.SquadLeader.Pawn.Weapon.GetFireMode(1).bIsFiring)
					&& (VSize(B.Squad.SquadLeader.Pawn.Location - StartTrace) < TraceRange) )
				{
					Other = Weapon.Trace(HitLocation, HitNormal, B.Squad.SquadLeader.Pawn.Location, StartTrace, true);
					if ( Other == B.Squad.SquadLeader.Pawn )
					{
						B.Focus = B.Squad.SquadLeader.Pawn;
						if ( B.Focus != LockedPawn )
							SetLinkTo(B.Squad.SquadLeader.Pawn);
						B.SetRotation(Rotator(B.Focus.Location - StartTrace));
 						X = Normal(B.Focus.Location - StartTrace);
 					}
 					else if ( B.Focus == B.Squad.SquadLeader.Pawn )
						bShouldStop = true;
				}
 				else if ( B.Focus == B.Squad.SquadLeader.Pawn )
					bShouldStop = true;
			}
		}

		if ( LockedPawn != None )
		{
			EndTrace = LockedPawn.Location + LockedPawn.BaseEyeHeight*Vect(0,0,0.5); // beam ends at approx gun height
			if ( Instigator.Role == ROLE_Authority )
			{
				V = Normal(EndTrace - StartTrace);
				if ( (V dot X < LinkFlexibility) || LockedPawn.Health <= 0 || LockedPawn.bDeleteMe || (VSize(EndTrace - StartTrace) > 1.5 * TraceRange) )
				{
					SetLinkTo( None );
				}
			}
		}

        if ( LockedPawn == None )
        {
            if ( Bot(Instigator.Controller) != None )
            {
				if ( bInitAimError )
				{
					CurrentAimError = AdjustAim(StartTrace, AimError);
					bInitAimError = false;
				}
				else
				{
					BoundError();
					CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;
				}

				// smooth aim error changes
				Step = 7500.0 * dt;
				if ( DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw )
				{
					CurrentAimError.Yaw += Step;
					if ( !(DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw) )
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				else
				{
					CurrentAimError.Yaw -= Step;
					if ( DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw )
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;
				if ( BoundError() )
					DesiredAimError = AdjustAim(StartTrace, AimError);
				CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;

				if ( Instigator.Controller.Target == None )
					Aim = Rotator(Instigator.Controller.FocalPoint - StartTrace);
				else
					Aim = Rotator(Instigator.Controller.Target.Location - StartTrace);

				Aim.Yaw = CurrentAimError.Yaw;

				// save difference
				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;
			}
			else
	            Aim = GetPlayerAim(StartTrace, AimError);

            X = Vector(Aim);
            EndTrace = StartTrace + TraceRange * X;
        }

        Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
        if ( Other != None && Other != Instigator )
			EndEffect = HitLocation;
		else
			EndEffect = EndTrace;

		if ( Beam != None )
			Beam.EndEffect = EndEffect;

		if ( Instigator.Role < ROLE_Authority )
		{
			if ( LinkGun.ThirdPersonActor != None )
			{
				if ( LinkGun.Linking || ((Other != None) && (Instigator.PlayerReplicationInfo.Team != None) && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
				{
					if (Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0)
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
				}
				else
				{
					if ( LinkGun.Links > 0 )
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
				}
			}
			return;
		}
        if ( Other != None && Other != Instigator )
        {
            // target can be linked to
            if ( IsLinkable(Other) )
            {
                if ( Other != lockedpawn )
                    SetLinkTo( Pawn(Other) );

                if ( lockedpawn != None )
                    LinkBreakTime = LinkBreakDelay;
            }
            else
            {
                // stop linking
                if ( lockedpawn != None )
                {
                    if ( LinkBreakTime <= 0.0 )
                        SetLinkTo( None );
                    else
                        LinkBreakTime -= dt;
                }

                // beam is updated every frame, but damage is only done based on the firing rate
                if ( bDoHit )
                {
                    if ( Beam != None )
						Beam.bLockedOn = false;

                    Instigator.MakeNoise(1.0);

                    AdjustedDamage = AdjustLinkDamage( LinkGun, Other, Damage );

                    if ( !Other.bWorldGeometry )
                    {
                        if ( Level.Game.bTeamGame && Pawn(Other) != None && Pawn(Other).PlayerReplicationInfo != None
							&& Pawn(Other).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team) // so even if friendly fire is on you can't hurt teammates
                            AdjustedDamage = 0;

						HealObjective = DestroyableObjective(Other);
						if ( HealObjective == None )
							HealObjective = DestroyableObjective(Other.Owner);
						if ( HealObjective != None && HealObjective.TeamLink(Instigator.GetTeamNum()) )
						{
							SetLinkTo(None);
							bIsHealingObjective = true;
                            
                            WM = class'WeaponModifier_Repair'.static.GetFor(Weapon);
                            if(WM != None) {
                                WM.Identify();
                                AdjustedDamage *= 1.0 + WM.Modifier * WM.BonusPerLevel; //The actual Repair gun effect
                            }
                            
                            OldHealth = HealObjective.Health;
                            if(HealObjective.HealDamage(AdjustedDamage, Instigator.Controller, DamageType)) {
                                if(HealObjective.Health > OldHealth) {
                                    Observer = class'RPGGameObjectiveObserver'.static.GetFor(HealObjective);
                                    if(Observer != None) {
                                        Observer.Healed(Instigator.Controller, HealObjective.Health - OldHealth);
                                    }
                                }
                            } else {
                                LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
                            }
						}
						else
							Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer*X, DamageType);

						if ( Beam != None )
							Beam.bLockedOn = true;
					}
				}
			}
		}

		// vehicle healing
		LinkedVehicle = Vehicle(LockedPawn);
		if ( LinkedVehicle != None && bDoHit )
		{
			AdjustedDamage = Damage * (1.5*Linkgun.Links+1) * Instigator.DamageScaling;
            
            //Check whether we're using a Repair weapon modifier
            WM = class'WeaponModifier_Repair'.static.GetFor(Weapon);
            if(WM != None) {
                WM.Identify();
                AdjustedDamage *= 1.0 + WM.Modifier * WM.BonusPerLevel; //The actual Repair gun effect
            }
			
			if(Instigator.HasUDamage())
				AdjustedDamage *= 2;
			
			if(LinkedVehicle.HealDamage(AdjustedDamage, Instigator.Controller, DamageType))
			{
				if(!LinkedVehicle.IsVehicleEmpty()) //only if somebody's inside
				{
                    //experience for linking
                    class'Util'.static.DoHealableDamage(
                        Instigator, LinkedVehicle, AdjustedDamage, class'RPGRules'.default.EXP_VehicleRepair);
                }
			}
			else
			{
				LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
			}
		}
		LinkGun(Weapon).Linking = (LockedPawn != None) || bIsHealingObjective;

		if ( bShouldStop )
			B.StopFiring();
		else
		{
			// beam effect is created and destroyed when firing starts and stops
			if ( (Beam == None) && bIsFiring )
			{
				if(LinkGun.bOLTeamGames)
				{
					Beam = Weapon.Spawn(class'RPGLinkBeamEffect', Instigator );
					RPGLinkBeamEffect(Beam).TeamIndex = Weapon.Instigator.PlayerReplicationInfo.Team.TeamIndex;
					RPGLinkBeamEffect(Beam).SetTeamEffects();
				}
				else
				{
					Beam = Weapon.Spawn(class'LinkBeamEffect', Instigator );
				}
				
				
				// vary link volume to make sure it gets replicated (in case owning player changed it client side)
				if ( SentLinkVolume == Default.LinkVolume )
					SentLinkVolume = Default.LinkVolume + 1;
				else
					SentLinkVolume = Default.LinkVolume;
			}

			if ( Beam != None )
			{
				if(RPGLinkGun(Weapon).bOLTeamGames)
				{
					switch(Weapon.Instigator.PlayerReplicationInfo.Team.TeamIndex)
					{
						case 0:
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
							break;
						case 1:
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
							break;
						case 2:
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
							break;
						case 3:
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
							break;
					}

					if ( LinkGun.Linking || ((Other != None) && (Instigator.PlayerReplicationInfo.Team != None) && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
						Beam.LinkColor = Instigator.PlayerReplicationInfo.Team.TeamIndex + 1;
					else
						Beam.LinkColor = 0;
				}
				else
				{
					if ( LinkGun.Linking || ((Other != None) && (Instigator.PlayerReplicationInfo.Team != None) && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
					{
						Beam.LinkColor = Instigator.PlayerReplicationInfo.Team.TeamIndex + 1;
						if ( LinkGun.ThirdPersonActor != None )
						{
							if ( Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0 )
								LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
							else
								LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
						}
					}
					else
					{
						Beam.LinkColor = 0;
						if ( LinkGun.ThirdPersonActor != None )
						{
							if ( LinkGun.Links > 0 )
								LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
							else
								LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
						}
					}
				}

				Beam.Links = LinkGun.Links;
				Instigator.AmbientSound = BeamSounds[Min(Beam.Links,3)];
				Instigator.SoundVolume = SentLinkVolume;
				Beam.LinkedPawn = LockedPawn;
				Beam.bHitSomething = (Other != None);
				Beam.EndEffect = EndEffect;
			}
		}
    }
    else
        StopFiring();

    bStartFire = false;
    bDoHit = false;
}

//OLTeamGames support
simulated function FlashMuzzleFlash()
{
	if(RPGLinkGun(Weapon).bOLTeamGames)
	{
		if (FlashEmitter != None)
		{
			switch(Weapon.Instigator.PlayerReplicationInfo.Team.TeamIndex)
			{
				case 0  : FlashEmitter.Skins[0] = Texture'XEffectMat.link_muz_red';     break;
				case 1  : FlashEmitter.Skins[0] = Texture'XEffectMat.link_muz_blue';    break;
				case 2  : FlashEmitter.Skins[0] = Texture'XEffectMat.link_muz_green';   break;
				case 3  : FlashEmitter.Skins[0] = Texture'XEffectMat.link_muz_yellow';  break;
			}
		}
		Super(WeaponFire).FlashMuzzleFlash();
	}
	else
	{
		Super.FlashMuzzleFlash();
	}
}

simulated function UpdateLinkColor( LinkAttachment.ELinkColor color )
{
	if(RPGLinkGun(Weapon).bOLTeamGames)
	{
		// Don't do anything - the beam should always be team colored, no matter what the link status is.
	}
	else
	{
		Super.UpdateLinkColor(Color);
	}
}

defaultproperties
{
	//BeamEffectClass=class'RPGLinkBeamEffect'
}
