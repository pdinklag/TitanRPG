class Artifact_Repulsion extends RPGArtifact;

var config float BlastRadius;
var config float MaxKnockbackTime;
var config float MaxKnockbackMomentum;
var config float MinKnockbackMomentum;

var Sound KnockbackSound;
var Material KnockbackOverlay;

var config bool bDestroysMines;

function BotFightEnemy(Bot Bot)
{
	local float Chance;

	if(
		Bot.bEnemyIsVisible &&
		class'WeaponModifier_Sturdy'.static.GetFor(Bot.Enemy.Weapon) == None &&
		VSize(Bot.Enemy.Location - Instigator.Location) <= BlastRadius
	)
	{
		Chance = 
			Bot.Tactics * 1.25 * 
			(1.0 - VSize(Bot.Enemy.Location - Instigator.Location) / BlastRadius);
		
		if(Bot.PlayerReplicationInfo != None && Bot.PlayerReplicationInfo.HasFlag != None)
			Chance += 0.1; //+10% if carrying the flag
		
		if(FRand() < Chance)
			Activate();
	}
}

function bool DoEffect()
{
	local Effect_Repulsion Repulsion;
	local ONSMineProjectile Mine;
	local float RepulsionScale;
	local vector Dir;
	local float Dist;
	local Pawn P;

	Spawn(class'FX_Repulsion', Instigator.Controller,,Instigator.Location);
	
	if(bDestroysMines)
	{
		//Destroy all nearby enemy mines
		foreach Instigator.VisibleCollidingActors(class'ONSMineProjectile', Mine, BlastRadius)
		{
			if(
				FastTrace(Mine.Location, Instigator.Location) &&
				Mine.TeamNum != Instigator.Controller.GetTeamNum()
			)
			{
				Mine.Explode(Mine.Location, vect(0, 0, 1));
			}
		}
	}
	
	foreach Instigator.VisibleCollidingActors(class'Pawn', P, BlastRadius)
	{
		if(FastTrace(P.Location, Instigator.Location))
		{
			Repulsion = Effect_Repulsion(class'Effect_Repulsion'.static.Create(P, Instigator.Controller, MaxKnockbackTime));
			if(Repulsion != None)
			{
				Dir = P.Location - Instigator.Location;
				Dist = FMax(1, VSize(Dir));
				Dir = Normal(Dir);

				RepulsionScale = 1 - FMax(0, Dist / BlastRadius);
				Repulsion.Momentum = Dir * (MinKnockbackMomentum + RepulsionScale * (MaxKnockbackMomentum - MinKnockbackMomentum));
				Repulsion.Start();
			}
		}
	}
	
	return true;
}

defaultproperties
{
	bAllowInVehicle=False
	BlastRadius=2048
	MaxKnockbackTime=2.00
	MaxKnockbackMomentum=1500
	MinKnockbackMomentum=250
	KnockbackSound=Sound'WeaponSounds.Misc.ballgun_launch'
	KnockbackOverlay=Shader'TitanRPG.Overlays.RedShader'
	Cooldown=5
	CostPerSec=25
	HudColor=(B=255,G=128,R=128)
	ArtifactID="Repulsion"
	Description="Knocks nearby enemies away."
	ActivateSound=Sound'WeaponSounds.BaseFiringSounds.BShieldGunFire'
	PickupClass=Class'ArtifactPickup_Repulsion'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Repulsion'
	ItemName="Repulsion"
}
