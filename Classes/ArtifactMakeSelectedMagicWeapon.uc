class ArtifactMakeSelectedMagicWeapon extends ArtifactWeaponMaker;

var ReplicatedArray Available;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Available;
}

//TODO: Rewrite (and adapt menu)

/*
simulated event PostBeginPlay()
{
	local int i;
	local MutTitanRPG RPGMut;

	Super.PostBeginPlay();

	if(Role == ROLE_Authority)
	{
		RPGMut = class'MutTitanRPG'.static.Instance(Level);
		
		Available = Spawn(class'ReplicatedArray');
		Available.Length = RPGMut.WeaponModifiers.Length;
		
		for(i = 0; i < Available.Length; i++)
			Available.ObjectArray[i] = RPGMut.WeaponModifiers[i].WeaponClass;
	}	
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super.GiveTo(Other, Pickup);
	
	if(PlayerController(Other.Controller) != None)
	{
		Available.SetOwner(Other.Controller);
		Available.Replicate();
	}
	else
	{
		Available.SetOwner(None);
	}
}

function ServerPickWeapon(class<RPGWeapon> RW)
{
	PickedWeapon = RW;
	Activate();
}

simulated function ClientShowMenu()
{
	class'SelectionMenu_WeaponModifier'.static.ShowFor(Self);
}

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	return PickedWeapon;
}

state Activated
{
	function BeginState()
	{
		if(PickedWeapon != None)
		{
			Super.BeginState();
		}
		else
		{
			GotoState('');
		
			if(Instigator.Controller.IsA('PlayerController'))
				ClientShowMenu();
			else
				ServerPickWeapon(PickBest());
		}
	}
	
	function EndState()
	{
		if(PickedWeapon != None)
			Super.EndState();
		
		PickedWeapon = None;
	}
}

simulated event Destroyed()
{
	if(Available != None)
		Available.Destroy();
	
	Super.Destroyed();
}

defaultproperties
{
	PickedWeapon=None

	bCanBreak=False
	bAvoidRepetition=False
	MinActivationTime=1.000000
	CostPerSec=25
	HudColor=(B=255,G=224,R=192)
	ArtifactID="SelMagicWeaponMaker"
	Description="Enchants a weapon with a modifier of your choice."
	//TODO: PickupClass=Class'ArtifactPickupMakeMagicWeapon'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.MagicMaker'
	ItemName="Enhanced Magic Maker"
}
*/
