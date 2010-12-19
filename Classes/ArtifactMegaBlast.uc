class ArtifactMegaBlast extends RPGArtifact;

function BotWhatNext(Bot Bot)
{
	if(Vehicle(Instigator) != None)
		return;

	if(
		!HasActiveArtifact(Instigator) &&
		Bot.Adrenaline >= CostPerSec &&
		Instigator.Health >= 75 && //should survive until then
		FRand() < 0.8 &&
		CountNearbyEnemies(class'MegaCharger'.default.Radius) >= 2
	)
	{
		Activate();
	}
}

function DoEffect()
{
	Spawn(class'MegaCharger', Instigator.Controller,,Instigator.Location);
	Destroy();
}

defaultproperties
{
	bAllowInVehicle=false
	CostPerSec=150
	HudColor=(G=128)
	ArtifactID="MegaBlast"
	bCanBeTossed=False
	Description="Causes a big badda boom."
	PickupClass=Class'ArtifactPickupMegaBlast'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.MegaBlast'
	ItemName="Mega Blast"
}
