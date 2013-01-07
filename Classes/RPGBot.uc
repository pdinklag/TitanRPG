class RPGBot extends InvasionBot; //optimized for InvasionPro 1.3 which is assumed to be final

var RPGAIBuild AIBuild;

var RPGWeapon LastWeaponMagicSuffered;
var class<DamageType> LastDamageTypeSuffered;

var RPGArtifact PickedArtifact;

var bool bInvasion;

//InvasionPro
var bool bInvasionPro;
var bool bDisableSpeed;
var bool bDisableBerserk;
var bool bDisableInvis;
var bool bDisableDef;

var config string InvasionProPackage;

event PreBeginPlay()
{
	bInvasion = Level.Game.IsA('Invasion');
	bInvasionPro = Level.Game.IsA('InvasionPro');
	
	if(bInvasionPro)
	{
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
				(bDisableBerserk && ComboName ~= "XGame.ComboBerserk") ||
				(bDisableInvis && ComboName ~= "XGame.ComboInvis") ||
				(bDisableDef && ComboName ~= "XGame.ComboDefensive")
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
	if(Weapon_Healer(Moron.Weapon) == None)
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
	if(FriendlyMonsterController(Seen.Controller) != None && SameTeamAs(Seen.Controller))
		return; //nevermind friendly monster

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

//InvasionPro
event Tick( float DeltaTime )
{
	local xPawn x;

	if(bInvasionPro)
	{
		if(Pawn != None)
		{
			PlayerReplicationInfo.SetPropertyText("PlayerHealth", string(Pawn.Health));
			PlayerReplicationInfo.SetPropertyText("PlayerHealthMax", string(Pawn.SuperHealthMax));

			x = xPawn(Pawn);
			if(x.CurrentCombo != None)
			{
				if(x.CurrentCombo.class == class'ComboDefensive' || x.CurrentCombo.class == class'ComboTeamBooster')
					PlayerReplicationInfo.SetPropertyText("IconNumber", "1");
				else if(x.CurrentCombo.class == class'ComboSpeed' || x.CurrentCombo.class == class'ComboSuperSpeed')
					PlayerReplicationInfo.SetPropertyText("IconNumber", "2");
				else if(x.CurrentCombo.class == class'ComboBerserk')
					PlayerReplicationInfo.SetPropertyText("IconNumber", "3");
				else if(x.CurrentCombo.class == class'ComboInvis')
					PlayerReplicationInfo.SetPropertyText("IconNumber", "4");
				else if(x.CurrentCombo.class == class'ComboCrate')
					PlayerReplicationInfo.SetPropertyText("IconNumber", "5");
				else if(x.CurrentCombo.class == class'ComboMiniMe')
					PlayerReplicationInfo.SetPropertyText("IconNumber", "6");
				else
					PlayerReplicationInfo.SetPropertyText("IconNumber", "7");
			}
			else
			{
				PlayerReplicationInfo.SetPropertyText("IconNumber", "0");
			}
		}
		else
		{
			PlayerReplicationInfo.SetPropertyText("PlayerHealth", "0");
			PlayerReplicationInfo.SetPropertyText("IconNumber", "0");
		}
	}

    Super.Tick(DeltaTime);
}

defaultproperties
{
	InvasionProPackage="InvasionProv1_3"
}
