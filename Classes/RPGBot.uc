class RPGBot extends InvasionBot;

var RPGAIBuild AIBuild;

var RPGWeapon LastWeaponMagicSuffered;
var class<DamageType> LastDamageTypeSuffered;

var RPGArtifact PickedArtifact;

//Check if this bot is actually playing Invasion
function bool IsInvasionBot()
{
	return (UnrealTeamInfo(PlayerReplicationInfo.Team) != None && 
		InvasionTeamAI(UnrealTeamInfo(PlayerReplicationInfo.Team).AI) != None);
}

function YellAt(Pawn Moron)
{
	//don't yell if being healed
	if(WeaponHealer(Moron.Weapon) == None)
	{
		if(!IsInvasionBot())
			Super.YellAt(Moron);
		else
			Super(xBot).YellAt(Moron);
	}
}


function bool AllowVoiceMessage(name MessageType)
{
	if(!IsInvasionBot())
		return Super.AllowVoiceMessage(MessageType);
	else
		return Super(xBot).AllowVoiceMessage(MessageType);
}

event SeeMonster(Pawn Seen)
{
	if(IsInvasionBot())
		Super.SeeMonster(Seen);
	else
		Super(xBot).SeeMonster(Seen);
}

function StopFiring()
{
	Super.StopFiring();
}

function ChooseAttackMode()
{
	Super.ChooseAttackMode();
}

//called by RPGONSAVRiLRocket
function IncomingMissile(Projectile P)
{
	local Inventory Inv;

	if(Pawn != None)
	{
		for(Inv = Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(Inv.IsA('RPGArtifact') && RPGArtifact(Inv).CanActivate())
				RPGArtifact(Inv).BotIncomingMissile(Self, P);
		}
	}
}

function ExecuteWhatToDoNext()
{
	local Inventory Inv;

	Super.ExecuteWhatToDoNext();
	
	if(Pawn != None)
	{
		for(Inv = Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(Inv.IsA('RPGArtifact') && RPGArtifact(Inv).CanActivate())
				RPGArtifact(Inv).BotWhatNext(Self);
		}
	}
}

function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	local Inventory Inv;

	Super.FightEnemy(bCanCharge, EnemyStrength);
	
	for(Inv = Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if(Inv.IsA('RPGArtifact') && RPGArtifact(Inv).CanActivate())
			RPGArtifact(Inv).BotFightEnemy(Self);
	}
}

function bool LoseEnemy()
{
	local Inventory Inv;

	if(Super.LoseEnemy())
	{
		for(Inv = Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(Inv.IsA('RPGArtifact') && RPGArtifact(Inv).CanActivate())
				RPGArtifact(Inv).BotLoseEnemy(Self);
		}
		return true;
	}
	else
	{
		return false;
	}
}

function Possess(Pawn aPawn)
{
	Super.Possess(aPawn);
}

function NotifyTakeHit(pawn InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
	Super.NotifyTakeHit(InstigatedBy, HitLocation, Damage, damageType, Momentum);
	
	if(InstigatedBy != None)
	{
		LastDamageTypeSuffered = damageType;
		
		if(class<WeaponDamageType>(damageType) != None)
			LastWeaponMagicSuffered = RPGWeapon(InstigatedBy.Weapon);
	}
}

defaultproperties
{
}
