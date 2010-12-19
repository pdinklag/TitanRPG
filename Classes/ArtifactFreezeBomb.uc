class ArtifactFreezeBomb extends RPGArtifact;

function BotWhatNext(Bot Bot)
{
	if(
		Instigator.Health >= 75 && //should survive until then
		FRand() < 0.6 &&
		CountNearbyEnemies(class'FreezeBombCharger'.default.Radius) >= 2
	)
	{
		Activate();
	}
}

function DoEffect()
{
	Spawn(class'FreezeBombCharger', Instigator.Controller,,Instigator.Location);
	Destroy();
}

defaultproperties
{
	bAllowInVehicle=False
	CostPerSec=100
	HudColor=(B=255,G=224,R=224)
	ArtifactID="FreezeBomb"
	bCanBeTossed=False
	Description="Immobilizes nearby enemies."
	PickupClass=Class'ArtifactPickupFreezeBomb'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.FreezeBomb'
	ItemName="Freeze Bomb"
}
