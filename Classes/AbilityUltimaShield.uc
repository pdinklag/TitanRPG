class AbilityUltimaShield extends RPGAbility;

defaultproperties
{
	AbilityName="Ultima Shield"
	Description="Protects you from ultima blasts while on foot.|Also protects your translocator beacon if it flies into an Ultima explosion."
	StartingCost=80
	MaxLevel=1
	RequiredAbilities(0)=(AbilityClass=class'AbilityHealthBonus',Level=3)
	RequiredAbilities(1)=(AbilityClass=class'AbilityDamageReduction',Level=6)
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityUltima',Level=1)
	Category=class'AbilityCategory_Misc'
}
