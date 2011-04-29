class ArtifactHealingBlast extends RPGArtifact;

function BotWhatNext(Bot Bot)
{
	if(
		Instigator.Health >= 50 && //should survive until then
		CountNearbyEnemies(class'Blast_Heal'.default.Radius, true) >= 2
	)
	{
		Activate();
	}
}

function DoEffect()
{
	local AbilityLoadedMedic LM;
	local RPGPlayerReplicationInfo RPRI;
	local Blast_Heal Blast;

	Blast = Spawn(class'Blast_Heal', Instigator.Controller,,Instigator.Location);
	if(Blast != None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
		{
			LM = AbilityLoadedMedic(RPRI.GetOwnedAbility(class'AbilityLoadedMedic'));
			if(LM != None)
				Blast.MaxHealth = LM.GetHealMax();
			
			Blast.EXPMultiplier = RPRI.HealingExpMultiplier;
		}
	}
}

defaultproperties
{
	bAllowInVehicle=False
	CostPerSec=0
	Cooldown=60
	HudColor=(B=255,G=0,R=0)
	ArtifactID="Healing Blast"
	bCanBeTossed=False
	Description="Heals nearby teammates."
	PickupClass=Class'ArtifactPickupHealingBlast'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.HealingBomb'
	ItemName="Healing Blast"
}
