//TitanRPG game type specific settings
class RPGGameSettings extends Object
	config(TitanRPG)
	PerObjectConfig;

var config bool bAllowTrans;
var config float TransTossForceScale;

var config bool bAllowVehicles;

var config float ExpScale;
var config float ExpForDamageScale;
var config bool bExpForKillingBots;

var config bool bAllowArtifacts;
var config bool bAllowAbilities;
var config bool bEnablePickupSpawner;

var config bool bNoUnidentified; //no unidentified items
var config bool bMagicalStartingWeapons;
var config float WeaponModifierChance;

var config array<class<RPGAbility> > ForbiddenAbilities;
var config array<class<RPGArtifact> > ForbiddenArtifacts;

function bool AllowArtifact(class<RPGArtifact> ArtifactClass)
{
	local int i;

	if(!bAllowArtifacts)
		return false;

	for(i = 0; i < ForbiddenArtifacts.Length; i++)
	{
		if(ForbiddenArtifacts[i] == ArtifactClass)
			return false;
	}
	return true;
}

function bool AllowAbility(class<RPGAbility> AbilityClass)
{
	local int i;

	if(!bAllowAbilities)
		return false;

	for(i = 0; i < ForbiddenAbilities.Length; i++)
	{
		if(ForbiddenAbilities[i] == AbilityClass)
			return false;
	}
	return true;
}

defaultproperties
{
	bAllowTrans=True
	bAllowVehicles=True
	
	ExpScale=1.000000
	ExpForDamageScale=1.000000
	bExpForKillingBots=True
	
	TransTossForceScale=1.000000
	
	bAllowAbilities=True
	bAllowArtifacts=True
    bEnablePickupSpawner=True
	
	bNoUnidentified=True
	bMagicalStartingWeapons=False
	WeaponModifierChance=0.666667
}
