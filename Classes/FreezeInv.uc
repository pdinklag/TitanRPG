class FreezeInv extends Inventory;

var Controller InstigatorController;
var Pawn PawnOwner;
var int Modifier;

var class <xEmitter> FreezeEffectClass;
var Material ModifierOverlay;

var bool stopped;
var float SpeedModifier;

//Old values
var float JumpZ;
var float DodgeSpeedZ;
var float DodgeSpeedFactor;
var bool bCanDoubleJump;
var bool bCanWallDodge;
var bool bCanDodgeDoubleJump;
var int MaxMultiJump;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		PawnOwner;

	reliable if (Role == ROLE_Authority)
		stopped;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Instigator != None)
		InstigatorController = Instigator.Controller;

	SetTimer(0.5, true);
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local Pawn OldInstigator;

	if(Other == None)
	{
		destroy();
		return;
	}

	stopped = false;
	if (InstigatorController == None)
		InstigatorController = Other.Controller;

	//want Instigator to be the one that caused the freeze
	OldInstigator = Instigator;
	Super.GiveTo(Other);
	PawnOwner = Other;

	Instigator = OldInstigator;
	class'SyncOverlayMaterial'.static.Sync(PawnOwner, ModifierOverlay, LifeSpan - 2, true);

	startEffect();
}

function startEffect()
{
	if(PawnOwner != None)
	{
		SpeedModifier = 1.f - FMin(
			class'WeaponFreeze'.default.BonusPerLevel * Modifier,
			class'WeaponFreeze'.default.FreezeMax
		);

		class'Util'.static.PawnScaleSpeed(PawnOwner, SpeedModifier);
		if(xPawn(PawnOwner) != None)
		{
			JumpZ = PawnOwner.JumpZ;
			DodgeSpeedZ = PawnOwner.DodgeSpeedZ;
			DodgeSpeedFactor = PawnOwner.DodgeSpeedFactor;

			bCanDoubleJump = PawnOwner.bCanDoubleJump;
			bCanWallDodge = PawnOwner.bCanWallDodge;

			bCanDodgeDoubleJump = xPawn(PawnOwner).bCanDodgeDoubleJump;
			MaxMultiJump = xPawn(PawnOwner).MaxMultiJump;

			PawnOwner.JumpZ = -0.1; //prevents playing a very loud landing sound
			PawnOwner.DodgeSpeedZ = 0;
			PawnOwner.DodgeSpeedFactor = 0;

			PawnOwner.bCanDoubleJump = False;
			PawnOwner.bCanWallDodge = False;

			xPawn(PawnOwner).bCanDodgeDoubleJump = False;
			xPawn(PawnOwner).MultiJumpRemaining = 0;
			xPawn(PawnOwner).MaxMultiJump = 0;
		}
	}
}

simulated function Timer()
{
	local Actor A;

	if (!stopped) {
		if (Level.NetMode != NM_DedicatedServer && PawnOwner != None &&
		    PawnOwner.IsLocallyControlled() && PlayerController(PawnOwner.Controller) != None)
			PlayerController(PawnOwner.Controller).ReceiveLocalizedMessage(class'FreezeConditionMessage', 0);

		if (Role == ROLE_Authority) {
			if(Owner != None)
				A = PawnOwner.spawn(class'IceSmokeEffect', PawnOwner,, PawnOwner.Location, PawnOwner.Rotation);

			if(!class'WeaponFreeze'.static.canTriggerPhysics(PawnOwner)) {
				stopEffect();
				return;
			}

			if(LifeSpan <= 0.5) {
				stopEffect();
				return;
			}

			if (Owner == None) {
				Destroy();
				return;
			}

			if (Instigator == None && InstigatorController != None)
				Instigator = InstigatorController.Pawn;
		}
	}
}

function stopEffect()
{
	if(stopped)
		return;

	stopped = true;

	if(PawnOwner != None) 
	{
		if(SpeedModifier != 0.f)
			class'Util'.static.PawnScaleSpeed(PawnOwner, 1.f / SpeedModifier);

		if(xPawn(PawnOwner) != None)
		{
			PawnOwner.JumpZ = JumpZ;
			PawnOwner.DodgeSpeedZ = DodgeSpeedZ;
			PawnOwner.DodgeSpeedFactor = DodgeSpeedFactor;

			PawnOwner.bCanDoubleJump = bCanDoubleJump;
			PawnOwner.bCanWallDodge = bCanWallDodge;

			xPawn(PawnOwner).bCanDodgeDoubleJump = bCanDodgeDoubleJump;
			xPawn(PawnOwner).MultiJumpRemaining = MaxMultiJump;
			xPawn(PawnOwner).MaxMultiJump = MaxMultiJump;
		}
	}
}

function Destroyed()
{
	stopEffect();

	Super.Destroyed();
}

defaultproperties
{
	ModifierOverlay=Shader'<? echo($packageName); ?>.Overlays.GreyShader'
	bOnlyRelevantToOwner=False
	bAlwaysRelevant=True
	bReplicateInstigator=True
}
