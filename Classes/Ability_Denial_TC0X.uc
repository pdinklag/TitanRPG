/*
	TC06-compatibility for Denial
	Called TC0X because of "class name shouldn't end in a digit", also it fits.
*/
class Ability_Denial_TC0X extends Ability_Denial;

defaultproperties
{
	bTC0X=True
	ExtraSavingLevel=2
	MaxLevel=3
	LevelDescription(0)="Level 1 of this ability prevents you from dropping your weapon when you die."
	LevelDescription(1)="Level 2 allows you to respawn with the weapon and ammo you were using when you died."
	LevelDescription(2)="If you have Loaded Artifacts or Loaded Medic, you may buy Level 3 which always saves all of your weapons (save for super weapons)."
	LevelCost(0)=10
	LevelCost(1)=20
	LevelCost(2)=25
}
