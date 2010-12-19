//I present to you: NULL VEHICLES!! they're evil... -pd
class VehicleMagicNullEntropy extends VehicleMagic;

function AdjustTargetDamage(out int Damage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local NullEntropyInv Inv;
	local Pawn P;

	if(Damage > 0)
	{
		P = Pawn(Victim);
		if(!class'WeaponNullEntropy'.static.CanBeNulled(P))
			return;

		Inv = spawn(class'NullEntropyInv', P,,, rot(0,0,0));
		if(Inv == None)
			return;
 
		//acts like a Null Entropy + 5 weapon
		Inv.LifeSpan = 5;
		Inv.Modifier = 5;
		
		if(P.Weapon != None)
		{
			if (!P.Weapon.isA('WeaponReflection') &&
				!P.Weapon.isA('WeaponMagicNullifier'))
				Inv.GiveTo(P);
		}
		else
			Inv.GiveTo(P);
	}
}

defaultproperties
{
	MagicName="Null Entropy"
	NameSuffix=" of Null Entropy"
	OverlayMat=Shader'MutantSkins.Shaders.MutantGlowShader'
}