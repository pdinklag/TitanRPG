class GhostInv extends Inventory
	config(TitanRPG);

/*
	Mostly unedited from DruidsRPG210_TC06 ~pd
*/

var config float TOBase, TOMulti, TOWait;

var int OwnerAbilityLevel;
var array<Material> OldInstigatorSkins;
var Material OldInstigatorRepSkin;
var array<ColorModifier> GhostSkins;
var Controller OwnerController;
var vector RevivePoint;
var bool bDisabled;
var Color GhostColor;
var Sound GhostSound;
var float PrevDist;
var float TotalTime;
var bool bTimedOut;

replication
{
	reliable if (bNetDirty && Role == ROLE_Authority)
		bDisabled;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local int Count;
	local float Dist;
	local NavigationPoint RandNavPt;
	local int Team;
	local Inventory Inv;

	Super.GiveTo(Other, Pickup);

	if(Instigator == None)
	{
		bDisabled = true;
		return;
	}

	if(Instigator.Controller == None)
	{
		Instigator.TakeDamage(1, None, Instigator.Location, vect(0,0,0), class'DamageType');
		return;
	}

	OldInstigatorRepSkin = Instigator.RepSkin;

	Instigator.RepSkin = None;
	if(Instigator.Weapon != None)
		Instigator.Weapon.HolderDied();

	if(Instigator.PlayerReplicationInfo.HasFlag != None)
		Instigator.PlayerReplicationInfo.HasFlag.Drop(0.5 * Instigator.Velocity);

	//set physics to walking so that returned random destinations are valid for Instigator
	Instigator.SetPhysics(PHYS_Walking);

	do
	{
		Count++;
		RandNavPt = Instigator.Controller.FindRandomDest();
		
		if (RandNavPt == None)
			break;

		if(RandNavPt.bMayCausePain || RandNavPt.Location.Z <= RandNavPt.Region.Zone.KillZ ||
			(RandNavPt.IsA('FlyingPathNode') && !Instigator.bCanFly) )
		{
			RandNavPt = None;
			continue;
		}
		
		RevivePoint = RandNavPt.Location + vect(0,0,40);
		Dist = VSize(RevivePoint - Instigator.Location);
	} 
	until(
		(Dist < 15000 && (Dist > 1000 || !FastTrace(RevivePoint, Instigator.Location)) &&
		!FastTrace(RevivePoint - vect(0, 0, 500), RevivePoint)) ||
		Count >= 1000
	)

	if(RandNavPt == None || 
		( 
			(
				Dist < 15000 && 
				(
					Dist > 1000 || 
					!FastTrace(RevivePoint, Instigator.Location)
				) && 
				!FastTrace(RevivePoint - vect(0,0,500), RevivePoint)
			)
		) || 
		Count == 1000 ||
		(
			Other.Physics != PHYS_Walking && 
			Other.Physics != PHYS_Falling && 
			Other.Physics != PHYS_Swimming
		)
		
	) //Bad pathing - pick a start point
	{
		if(Instigator.getTeam() != None)
			Team = Instigator.getTeam().TeamIndex;
		else
			Team = 255;

		RandNavPt = Level.Game.FindPlayerStart(Instigator.Controller, Team);
		RevivePoint = RandNavPt.Location + vect(0, 0, 40);
	}

	OwnerController = Instigator.Controller;
	if(PlayerController(Instigator.Controller) != None)
	{
		Instigator.RemoteRole = ROLE_SimulatedProxy;
		PlayerController(OwnerController).CleanOutSavedMoves();
		PlayerController(OwnerController).EndZoom();
		OwnerController.Pawn = None;
		Instigator.Controller = None;
		OwnerController.GotoState('BaseSpectating');
		PlayerController(OwnerController).ClientGotoState('BaseSpectating', '');
		PlayerController(OwnerController).SetViewTarget(Instigator);
		PlayerController(OwnerController).ClientSetViewTarget(Instigator);
		PlayerController(OwnerController).ClientSetBehindView(true);
	}
	else
	{
		Instigator.Controller.PendingStasis();
		Instigator.Controller.Pawn = None;
		Instigator.Controller = None;
	}

	for(Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(RPGArtifact(Inv) != None)
			RPGArtifact(Inv).GotoState('');
	}
	
	if(Instigator.Weapon != None)
		Instigator.Weapon.ImmediateStopFire();

	Instigator.bIgnoreOutOfWorld = true;
	Instigator.SetCollision(false);
	Instigator.bCollideWorld = false;
	Instigator.SetPhysics(PHYS_Flying);
	Instigator.Health = 9999; //heh...I wonder if anyone will get the joke?
	
	if(Vehicle(Instigator) != None)
		Instigator.bNoTeamBeacon = true;

	Instigator.Velocity = Normal(RevivePoint - Instigator.Location) * (Instigator.AirSpeed + Instigator.AirSpeed * 0.5 * OwnerAbilityLevel);
	Instigator.AmbientSound = GhostSound;
	TotalTime = 0.0;
	PrevDist = VSize(Instigator.Location - RevivePoint);
	bTimedOut = false;

	//listen/standalone stuff
	if(Level.NetMode != NM_DedicatedServer)
	{
		CreateGhostSkins();
		Instigator.Skins = GhostSkins;
		if (Instigator.Weapon != None && Instigator.Weapon.ThirdPersonActor != None)
			Instigator.Weapon.ThirdPersonActor.bHidden = true;
	}
}

simulated function PostNetBeginPlay()
{
	if(Role < ROLE_Authority)
		SetTimer(0.1, true);
}

function DropFrom(vector StartLocation)
{
	Destroy();
}

simulated function CreateGhostSkins()
{
	local int x;

	OldInstigatorSkins = Instigator.Skins;
	for(x = 0; x < Instigator.Skins.length; x++)
	{
		GhostSkins[x] = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
		GhostSkins[x].Material = Instigator.Skins[x];
		GhostSkins[x].AlphaBlend = true;
		GhostSkins[x].RenderTwoSided = true;
		GhostSkins[x].Color = GhostColor;
	}
}

simulated function Timer()
{
	//client-side stuff
	if(Instigator == None)
		return;
		
	if(bDisabled)
	{
		Deactivate();
		return;
	}
	
	if(GhostSkins.length == 0)
		CreateGhostSkins();
	
	Instigator.Skins = GhostSkins;
	
	if(Instigator.Weapon != None && Instigator.Weapon.ThirdPersonActor != None)
		Instigator.Weapon.ThirdPersonActor.bHidden = true;

	return;
}

function Tick(float deltaTime)
{
	TotalTime = TotalTime + deltaTime;
	
	if(bDisabled)
		return;

	// if the game will reset in a few seconds give up immediately so the Controller/Pawn don't get screwed up
	// See: http://disastrousconsequences.com/dcforum/posts/list/0/3138.page - BF/EAS
	if ( Level.Game.ResetCountdown != 3 && VSize(Instigator.Location - RevivePoint) > VSize(Instigator.Velocity) * deltaTime
		&& (PrevDist >= VSize(Instigator.Location - RevivePoint) || PrevDist == 0.0 || TotalTime < 2.0)
		&& TotalTime < TOBase + (TOMulti * (4 - OwnerAbilityLevel)) && !bTimedOut
		&& (!Level.Game.IsA('Invasion') || Invasion(Level.Game).bWaveInProgress || Invasion(Level.Game).WaveCountDown < 14) )
	{
		PrevDist = VSize(Instigator.Location - RevivePoint);
		//refresh Instigator velocity to counter air friction
		Instigator.Velocity = Normal(RevivePoint - Instigator.Location) * (Instigator.AirSpeed + Instigator.AirSpeed * 0.5 * OwnerAbilityLevel);
		if (Instigator.HasAnim('HitL'))
			Instigator.PlayAnim('HitL',,0.1);
		return;
	}else if (TotalTime >= TOBase + (TOMulti * (4 - OwnerAbilityLevel)) && TotalTime < TOWait + TOBase + (TOMulti * (4 - OwnerAbilityLevel)))
	{
		bTimedOut = true;
		Instigator.Velocity = vect(0,0,0);
		Instigator.SetLocation(RevivePoint);
	}else
	{
		if (PrevDist < VSize(Instigator.Location - RevivePoint))
		{
			Warn("GHOST: PrevDist = "@PrevDist@" < VSize(Ins.Loc - RP) = "@VSize(Instigator.Location - RevivePoint)@" !");
			Warn("GHOST: TotalTime = "@TotalTime@" !");
		}
		// Well, we should already be there, but if for some reason we're not,
		// Say, like the end-of-wave stuff is in effect:
		Instigator.SetLocation(RevivePoint);
		bTimedOut = false;
		ReviveInstigator();
	}
}

function ReviveInstigator()
{
	if(OwnerController != None)
	{
		if (PlayerController(OwnerController) == None)
			OwnerController.bStasis = false;

		OwnerController.Possess(Instigator);
		Instigator.bIgnoreOutOfWorld = false;
		Instigator.AmbientSound = None;
		Instigator.Velocity = vect(0,0,0);
		Instigator.SetCollision(true, true, true);
		Instigator.bCollideWorld = true;
		Instigator.SetPhysics(PHYS_Falling);
		if(xPawn(Instigator) != None)
			xPawn(Instigator).PhysicsVolumeChange(Instigator.HeadVolume);
		
		if(Vehicle(Instigator) != None)
			Instigator.bNoTeamBeacon = Instigator.default.bNoTeamBeacon;
			
		switch(OwnerAbilityLevel)
		{
			case 1:
				Instigator.Health = 1;
				break;
			case 2:
				Instigator.Health = Instigator.default.Health;
				break;
			case 3:
				Instigator.Health = Instigator.HealthMax;
				break;
		}
		
		Level.Game.SetPlayerDefaults(Instigator);
		
		if(Instigator.Controller != None && (Instigator.Weapon == None || !Instigator.Weapon.HasAmmo()))
			Instigator.Controller.ClientSwitchToBestWeapon();
	}
	disable('Tick');
	bDisabled = true;
	Deactivate();
	GotoState('Deactivated');
}

simulated function Deactivate()
{
	local int x;

	if (Role == ROLE_Authority)
		Instigator.RepSkin = OldInstigatorRepSkin;
	if (Level.NetMode != NM_DedicatedServer)
	{
		Instigator.Skins = OldInstigatorSkins;
		if (GhostSkins.length != 0)
		{
			for (x = 0; x < GhostSkins.length; x++)
				Level.ObjectPool.FreeObject(GhostSkins[x]);
			GhostSkins.length = 0;
		}
		if (Instigator.Weapon != None && Instigator.Weapon.ThirdPersonActor != None)
			Instigator.Weapon.ThirdPersonActor.bHidden = false;
	}
}

simulated function Destroyed()
{
	// trying to track down rare "fly out of the world" bug some people have reported
	if (Role == ROLE_Authority && !bDisabled)
		ReviveInstigator();

	if (GhostSkins.length != 0)
		Deactivate();

	Super.Destroyed();
}

state Deactivated
{
	function BeginState()
	{
		if (Level.Game.IsA('Invasion'))
		{
			SetTimer(Level.TimeDilation, true);
		}
	}

	function Timer()
	{
		// check if an invasion wave has ended, and if so, destroy ourselves so that the ability will reactivate
		// (otherwise players can just do the same by suiciding right before wave end)
		if (!Invasion(Level.Game).bWaveInProgress && Invasion(Level.Game).WaveCountDown > 11)
		{
			Destroy();
		}
	}
}

defaultproperties
{
	OwnerAbilityLevel=3
	GhostColor=(B=255,G=255,R=255,A=64)
	GhostSound=Sound'GeneralAmbience.texture19'
	TOBase=4.000000
	TOMulti=4.000000
	TOWait=2.000000
	bOnlyRelevantToOwner=False
	bAlwaysRelevant=True
	bReplicateInstigator=True
}
