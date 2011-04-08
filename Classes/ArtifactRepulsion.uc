class ArtifactRepulsion extends RPGArtifact;

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
		WeaponSturdy(Bot.Enemy.Weapon) == None &&
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

function DoEffect()
{
	local EffectRepulsion Repulsion;
	local ONSMineProjectile Mine;
	local float RepulsionScale;
	local vector Dir;
	local float Dist;
	local Controller C, NextC;

	Spawn(class'RepulsionExplosion', Instigator.Controller,,Instigator.Location);
	
	if(bDestroysMines)
	{
		//Destroy all nearby enemy mines
		foreach DynamicActors(class'ONSMineProjectile', Mine)
		{
			if(Mine.TeamNum != Instigator.Controller.GetTeamNum() &&
				VSize(Mine.Location - Instigator.Location) < BlastRadius && FastTrace(Mine.Location, Instigator.Location) )
			{
				Mine.Explode(Mine.Location, vect(0, 0, 1));
			}
		}
	}
	
	C = Level.ControllerList;
	while (C != None)
	{
		NextC = C.NextController;
		if (VSize(C.Pawn.Location - Instigator.Location) < BlastRadius && FastTrace(C.Pawn.Location, Instigator.Location) && !C.Pawn.isA('Vehicle'))
		{
			Repulsion = EffectRepulsion(class'EffectRepulsion'.static.Create(C.Pawn, Instigator.Controller, MaxKnockbackTime));
			if(Repulsion != None)
			{
				Dir = C.Pawn.Location - Instigator.Location;
				Dist = FMax(1, VSize(Dir));
				Dir = Normal(Dir);

				RepulsionScale = 1 - FMax(0, Dist / BlastRadius);
				Repulsion.Momentum = Dir * (MinKnockbackMomentum + RepulsionScale * (MaxKnockbackMomentum - MinKnockbackMomentum));
				Repulsion.Start();
			}
		}
		C = NextC;
	}
}

defaultproperties
{
	bAllowInVehicle=False
	BlastRadius=2000.000000
	MaxKnockbackTime=2.000000
	MaxKnockbackMomentum=3000.000000
	MinKnockbackMomentum=1000.000000
	KnockbackSound=Sound'WeaponSounds.Misc.ballgun_launch'
	KnockbackOverlay=Shader'<? echo($packageName); ?>.Overlays.RedShader'
	Cooldown=5
	CostPerSec=25
	HudColor=(B=255,G=128,R=128)
	ArtifactID="Repulsion"
	Description="Knocks nearby enemies away."
	ActivateSound=Sound'WeaponSounds.BaseFiringSounds.BShieldGunFire'
	PickupClass=Class'ArtifactPickupRepulsion'
	IconMaterial=Texture'<? echo($packageName); ?>.ArtifactIcons.Repulsion'
	ItemName="Repulsion"
}
