//-----------------------------------------------------------
//
//-----------------------------------------------------------
class NullEntropyInv extends Inventory;

var Pawn PawnOwner;
var Material ModifierOverlay;
var int Modifier;
var Sound NullEntropySound;

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local SyncNullEntropy Sync;

	if(Other == None)
	{
		destroy();
		return;
	}
	PawnOwner = Other;

	PawnOwner.SetPhysics(PHYS_None);
	enable('Tick');
	
	if(Modifier < 7)
	{
		LifeSpan = (Modifier / 3) + ((7 - Modifier) * 0.1);
		SetTimer(0.1, true);
	}
	else
		LifeSpan = (Modifier / 3);

	//fix the replication issue
	Sync = Spawn(class'SyncNullEntropy');
	Sync.Lifetime = LifeSpan;
	Sync.Target = PawnOwner;
	Sync.NullLocation = PawnOwner.Location;

	if(PawnOwner.Controller != None && PlayerController(PawnOwner.Controller) != None)
		PlayerController(PawnOwner.Controller).ReceiveLocalizedMessage(class'NullEntropyConditionMessage', 0);
		
	PawnOwner.PlaySound(NullEntropySound,,1.5 * PawnOwner.TransientSoundVolume,,PawnOwner.TransientSoundRadius);
	
	class'SyncOverlayMaterial'.static.Sync(PawnOwner, ModifierOverlay, LifeSpan, true);

	Super.GiveTo(Other);
}

function Tick(float deltaTime)
{
	if(PawnOwner == None || (PawnOwner.PlayerReplicationInfo != None && PawnOwner.PlayerReplicationInfo.HasFlag != None))
		return;

	if(PawnOwner.Physics != PHYS_NONE)
		PawnOwner.setPhysics(PHYS_NONE);
}

function destroyed()
{
	disable('Tick');
	if(PawnOwner != None && PawnOwner.Physics == PHYS_NONE)
		PawnOwner.SetPhysics(PHYS_Falling);
	super.destroyed();
}

function Timer()
{
	if(LifeSpan <= (7 - Modifier) * 0.1)
	{
		SetTimer(0, true);
		disable('Tick');		
		PawnOwner.SetPhysics(PHYS_Falling);
	}
}

defaultproperties
{
     ModifierOverlay=Shader'MutantSkins.Shaders.MutantGlowShader'
     NullEntropySound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
     bOnlyRelevantToOwner=False
     bAlwaysRelevant=True
     bReplicateInstigator=True
}
