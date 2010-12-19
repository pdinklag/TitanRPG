class ArtifactHealingBlast extends RPGArtifact;

function DoEffect()
{
	local AbilityLoadedMedic LM;
	local RPGPlayerReplicationInfo RPRI;
	local HealingBlastCharger Charger;

	Charger = Spawn(class'HealingBlastCharger', Instigator.Controller,,Instigator.Location);
	if(Charger != None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
		{
			LM = AbilityLoadedMedic(RPRI.GetOwnedAbility(class'AbilityLoadedMedic'));
			if(LM != None)
				Charger.MaxHealth = LM.GetHealMax();
			
			Charger.EXPMultiplier = RPRI.HealingExpMultiplier;
		}
	}
}

defaultproperties
{
	bAllowInVehicle=False
	CostPerSec=0
	UseDelay=60
	HudColor=(B=255,G=0,R=0)
	ArtifactID="Healing Blast"
	bCanBeTossed=False
	Description="Heals nearby teammates."
	PickupClass=Class'ArtifactPickupHealingBlast'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.HealingBomb'
	ItemName="Healing Blast"
}
