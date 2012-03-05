class Artifact_VehicleBoost extends RPGArtifact;

var config vector BoostForce; //Boost force (X = forward)
var config float BoostTrailLifeTime;

var array<SpeedTrail> Trails;

const MSG_Restriction = 0x1000;

var localized string MsgRestriction;

static function string GetMessageString(int Msg, optional int Value, optional Object Obj)
{
	switch(Msg)
	{
		case MSG_Restriction:
			return default.MsgRestriction;
	
		default:
			return Super.GetMessageString(Msg, Value, Obj);
	}
}

function BotWhatNext(Bot Bot)
{
	if(
		Bot.PlayerReplicationInfo != None &&
		Bot.PlayerReplicationInfo.HasFlag != None &&
		FRand() < 0.8
	)
	{
		Activate();
	}
}

function bool CanActivate()
{
	if(ONSWheeledCraft(Instigator) == None)
	{
		Msg(MSG_Restriction);
		return false;
	}
	
	return Super.CanActivate();
}

function bool DoEffect()
{
	local ONSVehicle OV; 
	
	DestroyTrails();

	OV = ONSVehicle(Instigator);

	if(ONSMobileAssaultStation(OV) != None)
		OV.KAddImpulse(8.f * default.BoostForce >> OV.Rotation, vect(0,0,0));
	else
		OV.KAddImpulse(default.BoostForce >> OV.Rotation, vect(0,0,0));

	if(OV.Health > 0)
	{
		OV.PlaySound(Sound'ONSVehicleSounds-S.PowerNode.PwrNodeBuild02',,2.0 * OV.TransientSoundVolume,,OV.TransientSoundRadius);

		if(ONSRV(OV) != None)
		{
			SpawnTrails(OV, 4);
			OV.AttachToBone(Trails[0], 'tire');
			OV.AttachToBone(Trails[1], 'tire02');
			OV.AttachToBone(Trails[2], 'tire03');
			OV.AttachToBone(Trails[3], 'tire04');
		}
		else if(ONSPRV(OV) != None || ONSMobileAssaultStation(OV) != None)
		{
			SpawnTrails(OV, 4);
			OV.AttachToBone(Trails[0], 'LeftFrontTIRE');
			OV.AttachToBone(Trails[1], 'RightFrontTIRE');
			OV.AttachToBone(Trails[2], 'LeftRearTIRE');
			OV.AttachToBone(Trails[3], 'RightRearTIRe');
		}
		else if(ONSGenericSD(OV) != None)
		{
			SpawnTrails(OV, 4);
			OV.AttachToBone(Trails[0], 'Object02');
			OV.AttachToBone(Trails[1], 'Object03');
			OV.AttachToBone(Trails[2], 'Object07');
			OV.AttachToBone(Trails[3], 'Object08');
		}
		else if(ONSArtillery(OV) != None)
		{
			SpawnTrails(OV, 6);
			OV.AttachToBone(Trails[0], 'Wheel_Left01');
			OV.AttachToBone(Trails[1], 'Wheel_Right01');
			OV.AttachToBone(Trails[2], 'Wheel_Left02');
			OV.AttachToBone(Trails[3], 'Wheel_Right02');
			OV.AttachToBone(Trails[4], 'Wheel_Left03');
			OV.AttachToBone(Trails[5], 'Wheel_Right03');
		}
		else if(ONSShockTank(OV) != None)
		{
			SpawnTrails(OV, 8);
			OV.AttachToBone(Trails[0], '8WheelerWheel01');
			OV.AttachToBone(Trails[1], '8WheelerWheel02');
			OV.AttachToBone(Trails[2], '8WheelerWheel03');
			OV.AttachToBone(Trails[3], '8WheelerWheel04');
			OV.AttachToBone(Trails[4], '8WheelerWheel05');
			OV.AttachToBone(Trails[5], '8WheelerWheel06');
			OV.AttachToBone(Trails[6], '8WheelerWheel07');
			OV.AttachToBone(Trails[7], '8WheelerWheel08');
		}

		SetTimer(BoostTrailLifeTime, false);
	}
	
	return true;
}

function Timer()
{
	DestroyTrails();
}

function SpawnTrails(Actor Ref, int Num)
{
	local int i;

	for(i = 0; i < Num; i++)
		Trails[i] = Ref.Spawn(class'SpeedTrail', Ref,, Ref.Location, Ref.Rotation);
}

function DestroyTrails()
{
	local int i;

	for(i = 0; i < Trails.Length; i++)
		Trails[i].Destroy();
		
	Trails.Remove(0, Trails.Length);
}

event Destroyed()
{
	DestroyTrails();
	Super.Destroyed();
}

defaultproperties
{
	BoostForce=(X=6000000.000000,Z=150000.000000)
	BoostTrailLifeTime=3.000000
	Cooldown=15
	MsgRestriction="The Nitro Boost can only be used in a wheeled vehicle."
	HudColor=(B=192,G=192,R=192)
	ArtifactID="NitroBoost"
	Description="Gives a boost to your vehicle."
	PickupClass=Class'ArtifactPickup_VehicleBoost'
	IconMaterial=Texture'TitanRPG.ArtifactIcons.nitroboost'
	ItemName="Nitro Boost"
}
