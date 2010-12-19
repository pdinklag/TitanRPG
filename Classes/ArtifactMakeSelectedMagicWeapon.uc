class ArtifactMakeSelectedMagicWeapon extends ArtifactWeaponMaker;

var class<RPGWeapon> PickedWeapon;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientShowMenu;
	
	reliable if(Role < ROLE_Authority)
		ServerPickWeapon;
}

function ServerPickWeapon(class<RPGWeapon> RW)
{
	PickedWeapon = RW;
	Activate();
}

function class<RPGWeapon> PickBest()
{
	return None;
}

simulated function ClientShowMenu()
{
	class'MagicWeaponMenu'.static.ShowFor(Self);
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

defaultproperties
{
	PickedWeapon = None;

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
