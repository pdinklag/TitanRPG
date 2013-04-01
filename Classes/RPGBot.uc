class RPGBot extends InvasionBot;

var RPGAIBuild AIBuild;

var RPGWeaponModifier LastModifierSuffered;
var class<DamageType> LastDamageTypeSuffered;

var RPGArtifact PickedArtifact;

var bool bInvasion;

var float AnnouncementDelay;

var Pawn Patient; //I'm his medic!

var PlayerReplicationInfo DenyPatient;
var float DenyPatientTime;

//InvasionPro
var bool bInvasionPro;
var bool bDisableSpeed;
var bool bDisableBerserk;
var bool bDisableInvis;
var bool bDisableDef;

var string InvasionProPackage;

event PreBeginPlay()
{
    local int x;

	bInvasion = Level.Game.IsA('Invasion');
	bInvasionPro = Level.Game.IsA('InvasionPro');
	
	if(bInvasionPro) {
        x = InStr(string(Level.Game.class), ".");
        InvasionProPackage = Left(string(Level.Game.class), x);
    
		PlayerReplicationInfoClass = 
			class<PlayerReplicationInfo>(DynamicLoadObject(InvasionProPackage $ ".InvasionProPlayerReplicationInfo", class'Class'));
	}

	Super.PreBeginPlay();
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if(bInvasionPro)
	{
		bDisableSpeed = bool(Level.Game.GetPropertyText("bDisableSpeed"));
		bDisableBerserk = bool(Level.Game.GetPropertyText("bDisableBerserk"));
		bDisableInvis = bool(Level.Game.GetPropertyText("bDisableInvis"));
		bDisableDef = bool(Level.Game.GetPropertyText("bDisableDef"));
	}
}

function SetPawnClass(string inClass, string inCharacter)
{
	if(inClass != "" && bInvasionPro)
		inClass = InvasionProPackage $ ".InvasionProxPawn";

	Super.SetPawnClass(inClass, inCharacter);
}

function TryCombo(string ComboName)
{
	local Controller C;
	local int i, ResurrectionCombo;

	if(!bInvasion)
	{
		Super.TryCombo(ComboName);
		return;
	}
	
    if ( !Pawn.InCurrentCombo() && !NeedsAdrenaline() )
    {
        if ( ComboName ~= "Random" )
        {
            ComboName = ComboNames[Rand(ArrayCount(ComboNames))];
		}
		else
		{
			ComboName = Level.Game.NewRecommendCombo(ComboName, self);
		
			if(bInvasion)
			{
				ResurrectionCombo = -1;
				for(i = 0; i < ArrayCount(ComboNames); i++)
				{
					if(class'RPGRules'.static.IsResurrectionCombo(ComboNames[i]))
					{
						ResurrectionCombo = i;
						break;
					}
				}
		
				if(ResurrectionCombo >= 0)
				{
					for(C = Level.ControllerList; C != None; C = C.NextController)
					{
						if(C.bIsPlayer && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.bOutOfLives)
						{
							//a player is out, use resurrection combo
							ComboName = ComboNames[ResurrectionCombo];
							break;
						}
					}
				}
			}
		}
		
		if(bInvasionPro)
		{
			if(
				(bDisableSpeed && ComboName ~= "XGame.ComboSpeed") ||
				(bDisableSpeed && ComboName ~= string(class'ComboSuperSpeed')) ||
				(bDisableBerserk && ComboName ~= "XGame.ComboBerserk") ||
				(bDisableInvis && ComboName ~= "XGame.ComboInvis") ||
				(bDisableDef && ComboName ~= "XGame.ComboDefensive") ||
                (bDisableDef && ComboName ~= string(class'ComboTeamBooster'))
			)
			{
				return;
			}
		}

        Pawn.DoComboName(ComboName);
    }
}

function YellAt(Pawn Moron)
{
	//don't yell if being healed
	if(class'WeaponModifier_Heal'.static.GetFor(Moron.Weapon) == None)
	{
		if(bInvasion)
			Super.YellAt(Moron);
		else
			Super(xBot).YellAt(Moron);
	}
}

function bool AllowVoiceMessage(name MessageType)
{
	if(bInvasion)
		return Super.AllowVoiceMessage(MessageType);
	else
		return Super(xBot).AllowVoiceMessage(MessageType);
}

event SeeMonster(Pawn Seen)
{
	if(FriendlyMonsterController(Seen.Controller) != None &&
        (FriendlyMonsterController(Seen.Controller).Master == Self || SameTeamAs(Seen.Controller)))
    {
		return; //nevermind friendly monster
    }

	if(bInvasion)
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

    //InvasionPro stuff
    if(bInvasionPro) {
        if(Pawn != None) {
            PlayerReplicationInfo.SetPropertyText("PlayerHealth", string(Pawn.Health));
            PlayerReplicationInfo.SetPropertyText("PlayerHealthMax", string(Pawn.SuperHealthMax));
        }
        else {
            PlayerReplicationInfo.SetPropertyText("PlayerHealth", "0");
        }
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
