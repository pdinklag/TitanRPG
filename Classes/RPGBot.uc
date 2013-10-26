class RPGBot extends InvasionBot;

var RPGAIBuild AIBuild;

var RPGWeaponModifier LastModifierSuffered;
var class<DamageType> LastDamageTypeSuffered;

var RPGArtifact PickedArtifact;

var float AnnouncementDelay;

var Pawn Patient; //I'm his medic!

var PlayerReplicationInfo DenyPatient;
var float DenyPatientTime;

function YellAt(Pawn Moron)
{
	//don't yell if being healed
	if(class'WeaponModifier_Heal'.static.GetFor(Moron.Weapon) == None)
	{
		Super(xBot).YellAt(Moron);
	}
}

function bool AllowVoiceMessage(name MessageType)
{
	return Super(xBot).AllowVoiceMessage(MessageType);
}

event SeeMonster(Pawn Seen)
{
	if(FriendlyMonsterController(Seen.Controller) != None &&
        (FriendlyMonsterController(Seen.Controller).Master == Self || SameTeamAs(Seen.Controller)))
    {
		return; //nevermind friendly monster
    }

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

function float RelativeStrength(Pawn Other) {
    if(Pawn == None || Other == None) {
        return 0;
    } else {
        return Super.RelativeStrength(Other);
    }
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

event Tick(float dt) {
    Super.Tick(dt);
    
    if(DenyPatient != None && Level.TimeSeconds > DenyPatientTime) {
        SendMessage(DenyPatient, 'Other', 7, 5, 'TEAM');
        DenyPatient = None;
    }
}

function AnnounceRole(PlayerController PC) {
    local RPGPlayerReplicationInfo RPRI;
    
    RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Self);
    if(RPRI != None && RPRI.HasAbility(class'Ability_Medic') > 0) {
        PC.ReceiveLocalizedMessage(class'LocalMessage_BotRole', 0, PlayerReplicationInfo);
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
    
    if(Patient != None) {
        if(GetOrders() != 'Follow') {
            SetTemporaryOrders('Follow', Patient.Controller);
            Log("MEDIC BOT: Re-assigning medic task");
        } else if(Patient.Health >= Patient.HealthMax || Patient.Health <= 0) {
            //done taking care of him - or failed!
            ClearTemporaryOrders();
            Patient = None;
            Log("MEDIC BOT: Done taking care of patient");
        }
    }
}

function bool Medicare(Pawn P) {
    if(P.IsA('Vehicle')) {
        P = Vehicle(P).Driver;
    }
    
    if(P == Patient) {
        return true;
    }

    if(Patient == None) {
        //no patient yet
        if(P.Health >= P.HealthMax) {
            //no need for a medic
            return false;
        } else {
            Patient = P;
            return true;
        }
    } else {
        //check if this guy needs it more
        if(P.Health < (Patient.Health - 10)) {
            Patient = P;
            return true;
        } else {
            return false;
        }
    }
}

function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	local Inventory Inv;
    
    if(
        Monster(Enemy) != None &&
        FriendlyMonsterController(Enemy.Controller) != None &&
        SameTeamAs(Enemy.Controller))
    {
        //Stop fighting friendly monsters
        Log(GetHumanReadableName() @ "stopped fighting a friendly" @ Enemy.class, 'DEBUG');
        Enemy = None;
        StopFiring();
        return;
    }

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
			LastModifierSuffered = class'RPGWeaponModifier'.static.GetFor(InstigatedBy.Weapon);
	}
}

simulated function float RateWeapon(Weapon w)
{
    local RPGWeaponModifier WM;

    WM = class'RPGWeaponModifier'.static.GetFor(W);
    if(WM != None) {
        return (WM.GetAIRating() + FRand() * 0.05);
    } else {
        return Super.RateWeapon(w);
    }
}

defaultproperties {
}
