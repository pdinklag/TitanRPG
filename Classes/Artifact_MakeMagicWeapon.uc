class Artifact_MakeMagicWeapon extends ArtifactBase_WeaponMaker;

function BotWhatNext(Bot Bot)
{
	if(
		!bActive &&
		!HasActiveArtifact(Instigator) &&
		Bot.Enemy == None &&
		Instigator.Weapon != None &&
		Instigator.Weapon.class == class'RPGWeapon' && //no magic
		FRand() < 0.25
	)
	{
		Activate();
	}
}

function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	local MutTitanRPG RPGMut;
	local int x, Chance;
	
	RPGMut = class'MutTitanRPG'.static.Instance(Level);

	Chance = Rand(RPGMut.TotalModifierChance);
	for (x = 0; x < RPGMut.WeaponModifiers.Length; x++)
	{
		Chance -= RPGMut.WeaponModifiers[x].Chance;
		if (Chance < 0 && RPGMut.WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
			return RPGMut.WeaponModifiers[x].WeaponClass;
	}

	return class'RPGWeapon';
}

defaultproperties
{
	bAvoidRepetition=True
	MinActivationTime=1.000000
	CostPerSec=25
	HudColor=(B=255,G=224,R=192)
	ArtifactID="MagicWeaponMaker"
	Description="Randomly enchants a weapon."
	PickupClass=Class'ArtifactPickup_MakeMagicWeapon'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.MagicMaker'
	ItemName="Magic Weapon Maker"
}
