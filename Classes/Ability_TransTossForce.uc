class Ability_TransTossForce extends RPGAbility;
	
var config array<float> LevelTossForceScale;

function ModifyWeapon(Weapon Weapon)
{
	local int i;
	local WeaponFire WF;

	for(i = 0; i < Weapon.NUM_FIRE_MODES; i++)
	{
		WF = Weapon.GetFireMode(i);
		if(WF.IsA('RPGTransFire'))
		{
			if(AbilityLevel <= MaxLevel) 
				RPGTransFire(WF).TossForceScale = LevelTossForceScale[AbilityLevel - 1];
			else
				Warn("Not enough LevelTossForceScales defined!");
		}
	}
}

defaultproperties
{
	LevelTossForceScale(0)=1.500000 //1800
	LevelTossForceScale(1)=1.750000 //2100
	LevelTossForceScale(2)=2.083333 //2500
	LevelTossForceScale(3)=2.500000 //3000
	LevelTossForceScale(4)=3.333333 //4000
	AbilityName="Enhanced Translocator"
	Description="Increases the range of your translocator each level."
	StartingCost=10
	CostAddPerLevel=10
	MaxLevel=5
	Category=class'AbilityCategory_Weapons'
}
