class Artifact_HealingBlast extends ArtifactBase_Blast;

function Blast SpawnBlast()
{
	local Ability_Medic LM;
	local RPGPlayerReplicationInfo RPRI;
	local Blast_Heal Blast;

	Blast = Blast_Heal(Super.SpawnBlast());
	if(Blast != None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
		if(RPRI != None)
		{
			LM = Ability_Medic(RPRI.GetOwnedAbility(class'Ability_Medic'));
			if(LM != None)
				Blast.MaxHealth = LM.GetHealMax();
			
			Blast.EXPMultiplier = RPRI.HealingExpMultiplier;
		}
	}
	return Blast;
}

defaultproperties
{
	BlastClass=class'Blast_Heal'
	bFriendly=True
	MaxUses=0 //infinite

	CostPerSec=0
	Cooldown=60
	HudColor=(B=255,G=0,R=0)
	ArtifactID="Healing Blast"
	Description="Heals nearby teammates."
	PickupClass=Class'ArtifactPickup_HealingBlast'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.HealingBomb'
	ItemName="Healing Blast"
}
