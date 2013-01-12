class Artifact_Invis extends RPGArtifact;

var config float EnemyRadius;
var config int ExtraCostPerEnemy;

var xPawn xInstigator;
var bool bResetInvis;

const MSG_InvisCombo = 0x1000;

var localized string MSG_Text_InvisCombo;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_InvisCombo:
			return default.MSG_Text_InvisCombo;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function int NearbyEnemies()
{
	local Controller C;
	local int n;
	
	if(Instigator == None)
		return 0;
	
	n = 0;
	for(C = Level.ControllerList; C != None; C= C.NextController)
	{
		if(
			C.bIsPlayer &&
			!C.SameTeamAs(Instigator.Controller) &&
			C.Pawn != None &&
			VSize(C.Pawn.Location - Instigator.Location) <= EnemyRadius
		)
		{
			n++;
		}
	}
	
	return n;
}

function bool CanActivate()
{
	xInstigator = xPawn(Instigator);
	if(xInstigator == None)
		return false;

	if(ComboInvis(xInstigator.CurrentCombo) != None)
	{
		Msg(MSG_InvisCombo);
		return false;
	}
		
	return Super.CanActivate();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();

		bResetInvis = true;
		xInstigator.SetInvisibility(9999.0f);
	}
	
	event Tick(float dt)
	{
		if(xInstigator != None && ComboInvis(xInstigator.CurrentCombo) != None)
		{
			//Invis combo was activated - keep combo active, deactivate artifact
			bResetInvis = false;
			GotoState('');
		}
	
		CurrentCostPerSec = CostPerSec + ExtraCostPerEnemy * NearbyEnemies();
		Super.Tick(dt);
	}

	function EndState()
	{
		if(bResetInvis)
			xInstigator.SetInvisibility(0);
	
		Super.EndState();
	}
}

defaultproperties
{
	ActivateSound=Sound'TitanRPG.SoundEffects.Invisible'
	MSG_Text_InvisCombo="You are already in the Invisible combo."
	EnemyRadius=1024.00
	ExtraCostPerEnemy=2
	CostPerSec=4
	MinActivationTime=1.000000
	bExclusive=True
	HudColor=(B=192,G=192,R=192)
	ArtifactID="Invis"
	Description="Makes you invisible when enemies are distant."
	PickupClass=Class'ArtifactPickup_Invis'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.invis'
	ItemName="Invisibility"
}
