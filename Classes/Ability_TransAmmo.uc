class Ability_TransAmmo extends RPGAbility;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientSetMaxAmmo;
}

simulated function ClientSetMaxAmmo(TransLauncher TL, int MaxAmmo)
{
	TL.RepAmmo = MaxAmmo;
	TL.AmmoChargeMax = float(MaxAmmo);
	TL.AmmoChargeF = float(MaxAmmo);
}

function ModifyWeapon(Weapon Weapon)
{
	local TransLauncher TL;

	TL = TransLauncher(Weapon);
	if(TL != None)
	{
		TL.RepAmmo = TL.default.RepAmmo + AbilityLevel * int(BonusPerLevel);
		TL.AmmoChargeMax = float(TL.RepAmmo);
		TL.AmmoChargeF = float(TL.RepAmmo);
		
		if(Role == ROLE_Authority && Level.NetMode != NM_Standalone)
			ClientSetMaxAmmo(TL, TL.RepAmmo);
	}
}

defaultproperties
{
	BonusPerLevel=1
	AbilityName="Translocator Ammo"
	Description="Increases the amount of ammunition for your translocator."
	StartingCost=5
	CostAddPerLevel=0
	MaxLevel=5
	Category=class'AbilityCategory_Weapons'
}
