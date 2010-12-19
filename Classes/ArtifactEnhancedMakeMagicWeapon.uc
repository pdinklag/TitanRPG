class ArtifactEnhancedMakeMagicWeapon extends ArtifactWeaponMaker;

var config array<class<RPGWeapon> > PossibleMagicTypes;

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	local Inventory Inv;
	local bool bAlreadyPresent;
	local class<RPGWeapon> RWClass;
	local int Tries;
	
	//try to not generate a weapon the user already has
	for(Tries = 0; Tries < 50; Tries++)
	{
		RWClass = PossibleMagicTypes[Rand(PossibleMagicTypes.Length)];
		
		bAlreadyPresent = false;
		for(Inv = Instigator.Inventory; Inv != None && !bAlreadyPresent; Inv = Inv.Inventory)
		{
			if(Inv.class == RWClass && RPGWeapon(Inv).ModifiedWeapon.class == WeaponType)
				bAlreadyPresent = true;
		}
		
		if(!bAlreadyPresent)
			break;
	}
	
	return RWClass;
}

defaultproperties
{
	bAllowInVehicle=False
	PossibleMagicTypes(0)=Class'WeaponNullEntropy'
	PossibleMagicTypes(1)=Class'WeaponFreeze'
	PossibleMagicTypes(2)=Class'WeaponQuickfoot'
	PossibleMagicTypes(3)=Class'WeaponRage'
	PossibleMagicTypes(4)=Class'WeaponVorpal'
	PossibleMagicTypes(5)=Class'WeaponInfSturdy'
	bCanBreak=False
	bAvoidRepetition=True
	MinActivationTime=1.000000
	CostPerSec=150
	HudColor=(B=255,G=192,R=208)
	ArtifactID="EnhancedMaker"
	bCanBeTossed=False
	Description="Enchants a weapon with a rare magic."
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.Enhanced'
	ItemName="Enhanced Magic Maker"
}
