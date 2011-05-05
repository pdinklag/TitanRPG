//TODO: Make Object class, needed on client end only
class RPGAbilityCategory extends RPGAbility;

simulated function int Cost()
{
	return 0;
}

simulated function string DescriptionText()
{
	return Description;
}

defaultproperties
{
	AbilityName="Category"
	Description="Description of Category"
}
	