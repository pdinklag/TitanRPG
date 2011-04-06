class ArtifactRepulsion extends RPGArtifact;

var config float BlastRadius;
var config float MaxKnockbackTime;
var config float MaxKnockbackMomentum;
var config float MinKnockbackMomentum;

var Sound KnockbackSound;
var Material KnockbackOverlay;

var config bool bDestroysMines;

function BotFightEnemy(Bot Bot)
{
	local float Chance;

	if(
		Bot.bEnemyIsVisible &&
		WeaponSturdy(Bot.Enemy.Weapon) == None &&
		VSize(Bot.Enemy.Location - Instigator.Location) <= BlastRadius
	)
	{
		Chance = 
			Bot.Tactics * 1.25 * 
			(1.0 - VSize(Bot.Enemy.Location - Instigator.Location) / BlastRadius);
		
		if(Bot.PlayerReplicationInfo != None && Bot.PlayerReplicationInfo.HasFlag != None)
			Chance += 0.1; //+10% if carrying the flag
		
		if(FRand() < Chance)
			Activate();
	}
}

function DoEffect()
{
	local ONSMineProjectile Mine;
	local float dist, KnockbackScale, KnockbackAmount;
	local vector dir;
	local Controller C, NextC;
	local Vector newLocation;

	Spawn(class'RepulsionExplosion', Instigator.Controller,,Instigator.Location);
	
	if(bDestroysMines)
	{
		//Destroy all nearby enemy mines
		foreach DynamicActors(class'ONSMineProjectile', Mine)
		{
			if(Mine.TeamNum != Instigator.Controller.GetTeamNum() &&
				VSize(Mine.Location - Instigator.Location) < BlastRadius && FastTrace(Mine.Location, Instigator.Location) )
			{
				Mine.Explode(Mine.Location, vect(0,0,1));
			}
		}
	}
	
	C = Level.ControllerList;
	while (C != None)
	{
		// loop round finding strongest enemy to attack
		NextC = C.NextController;
		if ( C.Pawn != None && C.Pawn != Instigator && C.Pawn.Health > 0 && !C.SameTeamAs(Instigator.Controller)
		     && VSize(C.Pawn.Location - Instigator.Location) < BlastRadius && FastTrace(C.Pawn.Location, Instigator.Location) && !C.Pawn.isA('Vehicle'))
		{
			/* FIXME: Use RPGEffect system
			if (C.Pawn.PlayerReplicationInfo != None && C.Pawn.PlayerReplicationInfo.HasFlag == None && C.Pawn.FindInventoryType(class'NullEntropyInv') == None)
			{
				if (C.Pawn.FindInventoryType(class'KnockbackInv') == None)
				{
					InvKnock = spawn(class'KnockbackInv', C.Pawn,,, rot(0,0,0));
					if(InvKnock != None)
					{
						dir = C.Pawn.Location - Instigator.Location;
						dist = FMax(1,VSize(dir));
						dir = dir/dist;
						KnockbackScale = 1 - FMax(0,dist/BlastRadius);

						// if they're not walking, falling, or hovering, 
						// the momentum won't affect them correctly, so make them hover.
						// this effect will end when the KnockbackInv expires.
						if(C.Pawn.Physics != PHYS_Walking && C.Pawn.Physics != PHYS_Falling && C.Pawn.Physics != PHYS_Hovering)
							C.Pawn.SetPhysics(PHYS_Hovering);

						// if they're walking, I need to bump them up 
						// in the air a bit or they won't be knocked back 
						// on no momentum weapons.
						if(C.Pawn.Physics == PHYS_Walking)
						{
							newLocation = C.Pawn.Location;
							newLocation.z += 10;
							C.Pawn.SetLocation(newLocation);
						}
						KnockbackAmount = (KnockbackScale*(MaxKnockbackMomentum-MinKnockbackMomentum)) + MinKnockbackMomentum;

						C.Pawn.TakeDamage(0, Instigator, C.Pawn.Location, KnockbackAmount * dir *0.8 * C.Pawn.Mass, class'Fell');

						InvKnock.LifeSpan = (KnockbackScale*(MaxKnockbackTime-1))+1;
						InvKnock.Modifier = 4;
						InvKnock.GiveTo(C.Pawn);
						
						class'SyncOverlayMaterial'.static.Sync(C.Pawn, KnockbackOverlay, 1.0, false);
						
						if(PlayerController(C) != None)
					 		PlayerController(C).ReceiveLocalizedMessage(class'KnockbackConditionMessage', 0);
						C.Pawn.PlaySound(KnockbackSound,,1.5 * C.Pawn.TransientSoundVolume,,C.Pawn.TransientSoundRadius);
					}
				}
			}
			*/
		}
		C = NextC;
	}
}

defaultproperties
{
	bAllowInVehicle=False
	BlastRadius=2000.000000
	MaxKnockbackTime=5.000000
	MaxKnockbackMomentum=3000.000000
	MinKnockbackMomentum=1000.000000
	KnockbackSound=Sound'WeaponSounds.Misc.ballgun_launch'
	KnockbackOverlay=Shader'<? echo($packageName); ?>.Overlays.RedShader'
	Cooldown=5
	CostPerSec=25
	HudColor=(B=255,G=128,R=128)
	ArtifactID="Repulsion"
	Description="Knocks nearby enemies away."
	ActivateSound=Sound'WeaponSounds.BaseFiringSounds.BShieldGunFire'
	PickupClass=Class'ArtifactPickupRepulsion'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.Repulsion'
	ItemName="Repulsion"
}
