class Artifact_EnhancedMakeMagicWeapon extends ArtifactBase_WeaponMaker hidedropdown;

var config array<class<RPGWeaponModifier> > PossibleModifiers;

function class<RPGWeaponModifier> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	local Inventory Inv;
	local bool bAlreadyPresent;
	local class<RPGWeaponModifier> WMClass;
	local int Tries;
	
	//try to not generate a weapon the user already has
	for(Tries = 0; Tries < 50; Tries++)
	{
		WMClass = PossibleModifiers[Rand(PossibleModifiers.Length)];
		
		bAlreadyPresent = false;
		for(Inv = Instigator.Inventory; Inv != None && !bAlreadyPresent; Inv = Inv.Inventory)
		{
			if(Inv.IsA('Weapon') && WMClass.static.GetFor(Weapon(Inv)) != None) {
				bAlreadyPresent = true;
                //can't break here because yay UnrealScript
            }
		}
		
		if(!bAlreadyPresent)
			break;
	}
	
	return WMClass;
}

defaultproperties
{
	bAllowInVehicle=False
	PossibleModifiers(0)=Class'WeaponModifier_NullEntropy'
	PossibleModifiers(1)=Class'WeaponModifier_Freeze'
	PossibleModifiers(2)=Class'WeaponModifier_Speed'
	PossibleModifiers(3)=Class'WeaponModifier_Rage'
	PossibleModifiers(4)=Class'WeaponModifier_Vorpal'
	PossibleModifiers(5)=Class'WeaponModifier_InfSturdy'
	bAvoidRepetition=True
	MinActivationTime=1.000000
	CostPerSec=150
	HudColor=(B=255,G=192,R=208)
	ArtifactID="EnhancedMaker"
	bCanBeTossed=False
	Description="Enchants a weapon with a rare magic."
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Enhanced'
	ItemName="Enhanced Magic Maker"
}
