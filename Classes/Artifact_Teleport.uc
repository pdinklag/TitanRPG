class Artifact_Teleport extends ArtifactBase_DelayedUse;

var Emitter myEmitter;

function BotFightEnemy(Bot Bot)
{
	if(Vehicle(Instigator) != None)
		return;
		
	if(
		Bot.bEnemyIsVisible &&
		Instigator.Health < 50 &&
		Bot.Skill >= 3 &&
		Bot.CombatStyle < 0 &&
		FRand() < 0.5)
	{
		Activate();
	}	
}

state Activated
{
	function bool DoEffect()
	{
		local NavigationPoint Dest;
		local vector PrevLocation;
		local int EffectNum;

		if (myEmitter != None)
		{
			myEmitter.SetBase(None);
			myEmitter.Kill();
			myEmitter = None;
		}

		//Dest = Instigator.Controller.FindRandomDest();
		Dest = Level.Game.FindPlayerStart(Instigator.Controller, Instigator.GetTeamNum());
		PrevLocation = Instigator.Location;
		
		if(Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.HasFlag != None)
			Instigator.PlayerReplicationInfo.HasFlag.Drop(vect(0, 0, 0));
		
		Instigator.SetLocation(Dest.Location + vect(0,0,40));
		if (xPawn(Instigator) != None)
			xPawn(Instigator).DoTranslocateOut(PrevLocation);
		
		if (Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None)
			EffectNum = Instigator.PlayerReplicationInfo.Team.TeamIndex;
		
		Instigator.SetOverlayMaterial(class'TransRecall'.default.TransMaterials[EffectNum], 1.0, false);
		Instigator.PlayTeleportEffect(false, false);
		
		return true;
	}
}

defaultproperties
{
	bAllowInVehicle=False
	CostPerSec=25
	MinActivationTime=1.000000
	PickupClass=Class'ArtifactPickup_Teleport'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Teleport'
	ItemName="Teleporter"
	ArtifactID="Teleport"
	Description="Teleports you to a random spawn point that belongs to your team."
	HudColor=(B=128,G=128,R=128)
}
