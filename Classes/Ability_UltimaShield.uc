class Ability_UltimaShield extends RPGAbility;

defaultproperties
{
	AbilityName="Ultima Shield"
	Description="Protects you from ultima blasts while on foot.|Also protects your translocator beacon if it flies into an Ultima explosion."
	StartingCost=80
	MaxLevel=1
	ForbiddenAbilities(0)=(AbilityClass=class'Ability_Ultima',Level=1)
	Category=class'AbilityCategory_Misc'
}
