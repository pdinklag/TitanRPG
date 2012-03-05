class Artifact_Protection extends RPGArtifact;

var Material EffectOverlay;
var config float DamageReduction;

var config bool bAllowWithFlag;

const MSG_NotWithFlag = 0x1000;

var localized string NotWithFlagMessage;
var localized string FlagText, BallText;

var float ClientDamageReduction;

replication
{
	reliable if(Role == ROLE_Authority && bNetDirty)
		ClientDamageReduction;
}

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_NotWithFlag:
			if(xBombFlag(Obj) != None)
				return Repl(default.NotWithFlagMessage, "$1", default.BallText);
			else
				return Repl(default.NotWithFlagMessage, "$1", default.FlagText);
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	if(Role == ROLE_Authority)
		ClientDamageReduction = DamageReduction;
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	Damage = Max(Damage - Damage * DamageReduction, 0);
}

function bool CanActivate()
{
	local Decoration Flag;

	Flag = Instigator.PlayerReplicationInfo.HasFlag;
	if(!bAllowWithFlag && Flag != None)
	{
		Msg(MSG_NotWithFlag,, Flag);
		return false;
	}

	return Super.CanActivate();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		
		class'Sync_OverlayMaterial'.static.Sync(Instigator, EffectOverlay, -1, true);
		SetTimer(0.5, true);
	}
	
	function Timer()
	{
		//If the Instigator grabs the flag, turn it off!
		if(!bAllowWithFlag && Instigator.PlayerReplicationInfo.HasFlag != None)
		{
			Activate();	//Don't be confused, this deactivates it...
		}
		else if(Instigator.OverlayMaterial == None)
		{
			class'Sync_OverlayMaterial'.static.Sync(Instigator, EffectOverlay, -1, true);
		}
	}

	function EndState()
	{
		if(Instigator != None)
			class'Sync_OverlayMaterial'.static.Sync(Instigator, None, 0, true);

		SetTimer(0, false);
		
		Super.EndState();
	}
}

defaultproperties
{
	ActivateSound=Sound'TitanRPG.SoundEffects.ProtectionArtifact'
	bAllowWithFlag=False
	EffectOverlay=Shader'TitanRPG.Overlays.GlobeOverlay'
	DamageReduction=0.666667
	NotWithFlagMessage="You cannot use this artifact while carrying $1."
	FlagText="the flag"
	BallText="the ball"
	CostPerSec=13
	MinActivationTime=1.000000
	HudColor=(B=128,G=192,R=224)
	ArtifactID="Globe"
	bExclusive=True
	Description="Reduces all incoming damage."
	PickupClass=Class'ArtifactPickup_Protection'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.Globe'
	ItemName="Protection"
}
