class RPGRules extends GameRules
	config(TitanRPG);

//for debugging, cba to code these up everytime, FALSE by default, can be toggled by "mutate damagelog"
var bool bDamageLog;

var Sound DisgraceAnnouncement, EagleEyeAnnouncement;

var MutTitanRPG RPGMut;
var int PointsPerLevel;
var float LevelDiffExpGainDiv;
var bool bAwardedFirstBlood;

var bool bGameEnded;

//These damage types are simply passed through without any ability, weapon magic or similar being able to scale it
var array<class<DamageType> > DirectDamageTypes;

//These damage types should not have UDamage applied
var array<class<DamageType> > NoUDamageTypes;

static function RPGRules Find(GameInfo G)
{
	local GameRules Rules;
	
	if(G != None)
	{
		for(Rules = G.GameRulesModifiers; Rules != None; Rules = Rules.NextGameRules)
		{
			if(RPGRules(Rules) != None)
				return RPGRules(Rules);
		}
	}

	return None;
}

event PostBeginPlay()
{
	local GameObjective GO;

	bGameEnded = false;

	SetTimer(Level.TimeDilation, true);

	//hack to deal with Assault's stupid hardcoded scoring setup
	if(ASGameInfo(Level.Game) != None)
	{
		foreach AllActors(class'GameObjective', GO)
			GO.Score = 0;
	}

	Super.PostBeginPlay();
}

//checks if the player that owns the specified RPGStatsInv is linked up to anybody and if so shares Amount EXP
//equally between them, otherwise gives it all to the lone player
static function ShareExperience(RPGPlayerReplicationInfo InstigatorRPRI, float Amount)
{
	local LinkGun Head, Link;
	local Controller C;
	local RPGPlayerReplicationInfo RPRI;
	local array<RPGPlayerReplicationInfo> Links;
	local int i;
	
	if(InstigatorRPRI.Controller.Pawn == None || InstigatorRPRI.Controller.Pawn.Weapon == None)
	{
		//dead or has no weapon, so can't be linked up
		InstigatorRPRI.AwardExperience(Amount);
	}
	else
	{
		Head = LinkGun(class'Util'.static.GetWeapon(InstigatorRPRI.Controller.Pawn.Weapon));
		if(Head == None)
		{
			// Instigator is not using a Link Gun
			InstigatorRPRI.AwardExperience(Amount);
		}
		else
		{
			//create a list of everyone that should share the EXP
			Links[0] = InstigatorRPRI;
			for(C = InstigatorRPRI.Level.ControllerList; C != None; C = C.NextController)
			{
				if(C.Pawn != None && C.Pawn.Weapon != None)
				{
					Link = LinkGun(class'Util'.static.GetWeapon(C.Pawn.Weapon));
					if(Link != None && Link.LinkedTo(Head))
					{
						RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
						if(RPRI != None)
							Links[Links.length] = RPRI;
					}
				}
			}
			
			// share the experience among the linked players
			Amount /= float(Links.Length);
			for(i = 0; i < Links.Length; i++)
				Links[i].AwardExperience(Amount);
		}
	}
}

// award EXP based on damage done
function AwardEXPForDamage(Controller InstigatedBy, RPGPlayerReplicationInfo InstRPRI, Pawn injured, float Damage)
{
	local float xp;

	if(
		InstigatedBy != Injured.Controller &&
		InstRPRI != None &&
		injured.IsA('Monster') &&
		injured.Controller != None &&
		!injured.Controller.IsA('FriendlyMonsterController')
	)
	{
		Damage = FMin(Damage, injured.Health);
		xp = RPGMut.GameSettings.ExpForDamageScale * (Damage / injured.HealthMax) * float(Monster(injured).ScoringValue);

		if(xp > 0)
		{
			if(InstigatedBy.IsA('FriendlyMonsterController'))
				InstRPRI.AwardExperience(xp * class'RPGGameStats'.default.EXP_FriendlyMonsterKill);
			else
				ShareExperience(InstRPRI, xp);
		}
	}
}

// calculate how much exp does a player get for killing another player of a certain level
function float GetKillEXP(RPGPlayerReplicationInfo KillerRPRI, RPGPlayerReplicationInfo KilledRPRI, optional float Multiplier)
{
	local float Diff;
	
	Diff = FMax(0, KilledRPRI.RPGLevel - KillerRPRI.RPGLevel);
	
	if(Diff > 0)
		Diff = (Diff * Diff) / LevelDiffExpGainDiv;
	
	//cap gained exp to enough to get to Killed's level
	if(KilledRPRI.RPGLevel - KillerRPRI.RPGLevel > 0 && Diff > (KilledRPRI.RPGLevel - KillerRPRI.RPGLevel) * KilledRPRI.NeededExp)
		Diff = (KilledRPRI.RPGLevel - KillerRPRI.RPGLevel) * KilledRPRI.NeededExp;
	
	Diff = float(int(Diff)); //round
	
	if(Multiplier > 0)
		Diff *= Multiplier;
	
	return FMax(class'RPGGameStats'.default.EXP_Frag, Diff); //at least EXP_Frag
}

function ScoreKill(Controller Killer, Controller Killed)
{
	local Controller Master;
	local RPGPlayerReplicationInfo KillerRPRI, KilledRPRI, RPRI;
	local int x;
	local Inventory Inv, NextInv;
	local vector TossVel, U, V, W;
	local bool bShare;
	
	if(Killed == None)
	{
		Super.ScoreKill(Killer, Killed);
		return;
	}

	//make killed pawn drop any artifacts he's got
	if(Killed.Pawn != None)
	{
		Inv = Killed.Pawn.Inventory;
		while (Inv != None)
		{
			NextInv = Inv.Inventory;
			if(RPGArtifact(Inv) != None)
			{
				TossVel = Vector(Killed.Pawn.GetViewRotation());
				TossVel = TossVel * ((Killed.Pawn.Velocity dot TossVel) + 500) + Vect(0,0,200);
				TossVel += VRand() * (100 + Rand(250));
				Inv.Velocity = TossVel;
				Killed.Pawn.GetAxes(Killed.Pawn.Rotation, U, V, W);
				Inv.DropFrom(Killed.Pawn.Location + 0.8 * Killed.Pawn.CollisionRadius * U - 0.5 * Killed.Pawn.CollisionRadius * V);
			}
			Inv = NextInv;
		}
	}
	
	Super.ScoreKill(Killer, Killed);

	//suicide
	if(Killer == Killed)
		return;

	//EXP for killing monsters and nonplayer AI vehicles/turrets
	//note: most monster EXP is awarded in NetDamage(); this just notifies abilities and awards an extra 1 EXP
	//to make sure the killer got at least 1 total (plus it's an easy way to know who got the final blow)
	if(Killed.IsA('MonsterController') || Killed.IsA('TurretController'))
	{
		if(Killer.IsA('FriendlyMonsterController'))
		{
			class'RPGGameStats'.static.RegisterWeaponKill(
				FriendlyMonsterController(Killer).Master.PlayerReplicationInfo, Killed.PlayerReplicationInfo, class'DummyWeaponMonster');
			
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(FriendlyMonsterController(Killer).Master);
			bShare = false;
		}
		else if(Killer.IsA('FriendlyTurretController'))
		{
			class'RPGGameStats'.static.RegisterWeaponKill(
				FriendlyTurretController(Killer).Master.PlayerReplicationInfo, Killed.PlayerReplicationInfo, class'DummyWeaponTurret');
			
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(FriendlyTurretController(Killer).Master);
			bShare = false;
		}
		else
		{
			RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Killer);
			bShare = true;
		}
	
		if(RPRI != None)
		{
			for(x = 0; x < RPRI.Abilities.length; x++)
			{
				if(RPRI.Abilities[x].bAllowed)
					RPRI.Abilities[x].ScoreKill(Killer, Killed, true);
			}

			if(bShare)
				ShareExperience(RPRI, class'RPGGameStats'.default.EXP_Frag);
			else
				RPRI.AwardExperience(class'RPGGameStats'.default.EXP_Frag);
		}
		
		return;
	}
	
	if(Killer == None)
		return;
	
	//if a summoned monster did the kill, award exp and score to master
	if(Killer.IsA('FriendlyMonsterController'))
	{
		Master = FriendlyMonsterController(Killer).Master;
		if(Master != None)
		{
			KillerRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Master);
			if(KillerRPRI != None)
			{
				KillerRPRI.AwardExperience(
					GetKillEXP(KillerRPRI, KilledRPRI, class'RPGGameStats'.default.EXP_FriendlyMonsterKill));
				
				Master.PlayerReplicationInfo.Score += 1;
			}
			
			if(Master.IsA('PlayerController'))
				PlayerController(Master).ReceiveLocalizedMessage(class'FriendlyMonsterKillerMessage',, Killer.PlayerReplicationInfo, Killed.PlayerReplicationInfo, Killer.Pawn);
			
			class'RPGGameStats'.static.RegisterWeaponKill(Master.PlayerReplicationInfo, Killed.PlayerReplicationInfo, class'DummyWeaponMonster');
		}
		return;
	}
	
	//same for constructed turrets
	if(Killer.IsA('FriendlyTurretController'))
	{
		Master = FriendlyTurretController(Killer).Master;
		if(Master != None)
		{
			KillerRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Master);
			if(KillerRPRI != None)
			{
				KillerRPRI.AwardExperience(class'RPGGameStats'.default.EXP_TurretKill);
				Master.PlayerReplicationInfo.Score += 1;
			}
			
			if(Master.IsA('PlayerController'))
				PlayerController(Master).ReceiveLocalizedMessage(class'FriendlyTurretKillerMessage',, Killer.PlayerReplicationInfo, Killed.PlayerReplicationInfo, Killer.Pawn);
			
			class'RPGGameStats'.static.RegisterWeaponKill(Master.PlayerReplicationInfo, Killed.PlayerReplicationInfo, class'DummyWeaponTurret');
		}
		return;
	}
	
	//get Killer RPRI
	KillerRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Killer);
	if(KillerRPRI == None)
	{
		Log("KillerRPRI not found for " $ Killer.GetHumanReadableName(), 'TitanRPG');
		return;
	}
	
	//Adjust adrenaline
	if(KillerRPRI.AboutToKill == Killed)
	{
		//no adrenaline for lightning rod kills
		if(KillerRPRI.KillingDamType == class'DamTypeLightningRod')
			Killer.Adrenaline = KillerRPRI.AdrenalineBeforeKill;
	}
	KillerRPRI.AboutToKill = None;
	
	//get killed RPRI
	KilledRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Killed);
	if (KilledRPRI == None)
	{
		Log("KilledRPRI not found for " $ Killed.GetHumanReadableName(), 'TitanRPG');
		return;
	}

	//team kill
	if(
		Killer == None ||
		Killer.SameTeamAs(Killed)
	)
	{
		return;
	}

	//get data
	for(x = 0; x < KillerRPRI.Abilities.length; x++)
	{
		if(KillerRPRI.Abilities[x].bAllowed)
			KillerRPRI.Abilities[x].ScoreKill(Killer, Killed, true);
	}
		
	for(x = 0; x < KilledRPRI.Abilities.length; x++)
	{
		if(KilledRPRI.Abilities[x].bAllowed)
			KilledRPRI.Abilities[x].ScoreKill(Killer, Killed, false);
	}

	if(!Killed.IsA('Bot') || RPGMut.GameSettings.bExpForKillingBots)
	{
		ShareExperience(KillerRPRI, GetKillEXP(KillerRPRI, KilledRPRI));
		
		if(Killed.Pawn != None && Killed.Pawn.GetSpree() > 4)
			ShareExperience(KillerRPRI, class'RPGGameStats'.default.EXP_EndSpree);
	}
}

function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local RPGPlayerReplicationInfo InjuredRPRI, InstRPRI, RPRI;
	local int x;
	local bool bZeroDamage;
	local Controller InjuredController, InstigatorController;
	local ONSVehicle V;
	local ONSWeaponPawn WP, InjuredWeaponPawn, InstigatorWeaponPawn; //"side turret"
	local Inventory Inv;
	local RPGArtifact A;
	local VehicleMagic VM;
	local AbilityVehicleEject Eject;
	local RPGWeapon RW;
	
	if(default.bDamageLog)
	{
		Log("=== RPGRules.NetDamage BEGIN ===");
		Log("OriginalDamage = " $ OriginalDamage);
		Log("Damage = " $ Damage);
		Log("injured = " $ injured);
		Log("instigatedBy = " $ instigatedBy);
		Log("HitLocation = " $ HitLocation);
		Log("Momentum = " $ Momentum);
		Log("DamageType = " $ DamageType);
		Log("");
	}
	
	//Filter UDamage if desired for this damage type
	if(
		class'Util'.static.InArray(DamageType, NoUDamageTypes) >= 0 &&
		instigatedBy != None &&
		instigatedBy.HasUDamage()
	)
	{
		OriginalDamage = int(float(OriginalDamage) / (2.f * instigatedBy.DamageScaling));
		Damage = int(float(Damage) / (2.f * instigatedBy.DamageScaling));
		
		if(default.bDamageLog)
		{
			Log("DEBUG: This damage type should not have UDamage applied!");
			Log("DEBUG: OriginalDamage = " $ OriginalDamage);
			Log("DEBUG: Damage = " $ Damage);
		}
	}
	
	//Direct damage types should not be processed by RPG
	if(class'Util'.static.InArray(DamageType, DirectDamageTypes) >= 0)
	{
		if(default.bDamageLog)
		{
			Log("DEBUG: This is a direct damage type and will not be processed further by RPG!");
			Log("=== RPGRules.NetDamage END ===");
		}
		
		return Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType); //pass-through
	}

	//Don't do anything to friendly monsters
	if(
		injured.IsA('Monster') &&
		FriendlyMonsterController(injured.Controller) != None &&
		instigatedBy != None &&
		instigatedBy.Controller != None &&
		instigatedBy.Controller.SameTeamAs(injured.Controller)
		)
	{
		if(default.bDamageLog)
		{
			Log("ZERO: Do not hurt friendly monsters!");
			Log("=== RPGRules.NetDamage END ===");
		}
	
		return 0;
	}
		
	//Pass through damage done by a monster to another monster
	if(Monster(injured) != None && Monster(instigatedBy) != None)
	{
		if(default.bDamageLog)
		{
			Log("SKIP: Damage done to a monster by another monster!");
			Log("=== RPGRules.NetDamage END ===");
		}
	
		return Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	}

	//Let Ejector Seat decide whether or not to ignore this damage type
	if(!injured.IsA('Vehicle'))
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(injured.Controller);
		if(RPRI != None)
		{
			Eject = AbilityVehicleEject(RPRI.GetOwnedAbility(class'AbilityVehicleEject'));
			if(Eject != None && Eject.HasJustEjected() && Eject.ProtectsAgainst(DamageType))
			{
				if(default.bDamageLog)
				{
					Log("ZERO: Damage was nullified by Ejector Seat!");
					Log("=== RPGRules.NetDamage END ===");
				}
				
				return 0;
			}
		}
	}
	
	//Check whether injured is a vehicle, if so, browse through the side turrets and see whether it is manned
	//Enables effects to work in/on vehicle side turrets
	V = ONSVehicle(injured);
	if(V != None && V.Controller == None)
	{
		for(x = 0; x < V.WeaponPawns.Length; x++)
		{
			WP = V.WeaponPawns[x];
			if(WP != None && WP.Controller != None)
			{
				InjuredWeaponPawn = WP;
				break;
			}
		}
	}
	
	//Same for instigator
	V = ONSVehicle(instigatedBy);
	if(V != None && V.Controller == None)
	{
		for(x = 0; x < V.WeaponPawns.Length; x++)
		{
			WP = V.WeaponPawns[x];
			if(WP != None && WP.Controller != None)
			{
				InstigatorWeaponPawn = WP;
				break;
			}
		}
	}
	
	if(default.bDamageLog)
	{
		Log("DEBUG: InstigatorWeaponPawn = " $ InjuredWeaponPawn);
		Log("DEBUG: InjuredWeaponPawn = " $ InjuredWeaponPawn);
	}

	if(
		injured == None ||
		instigatedBy == None ||
		(injured.Controller == None && InjuredWeaponPawn == None) ||
		(instigatedBy.Controller == None && InstigatorWeaponPawn == None)
	)
	{
		if(default.bDamageLog)
		{
			Log("SKIP: Not enough information for RPG processing!");
			Log("=== RPGRules.NetDamage END ===");
		}
	
		return Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	}

	InjuredController = injured.Controller;
	if(InjuredController == None)
		InjuredController = InjuredWeaponPawn.Controller;
		
	InstigatorController = instigatedBy.Controller;
	if(InstigatorController == None)
		InstigatorController = InstigatorWeaponPawn.Controller;
		
	if(default.bDamageLog)
	{
		Log("DEBUG: InjuredController = " $ InjuredController);
		Log("DEBUG: InstigatorController = " $ InstigatorController);
	}

	if(Damage <= 0)
	{
		Damage = Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
		if(Damage < 0)
		{
			if(default.bDamageLog)
			{
				Log("SKIP: Negative damage!");
				Log("=== RPGRules.NetDamage END ===");
			}
		
			return Damage;
		}
		else if (Damage == 0) //for zero damage, still process abilities/magic weapons so effects relying on hits instead of damage still work
		{
			if(default.bDamageLog)
				Log("INFO: Zero damage!");
		
			bZeroDamage = true;
		}
	}
	
	InstRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(InstigatorController);
	InjuredRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(InjuredController);
	
	if(default.bDamageLog)
	{
		Log("DEBUG: InstRPRI = " $ InstRPRI);
		Log("DEBUG: InjuredRPRI = " $ InjuredRPRI);
	}
	
	if(Monster(instigatedBy) == None && InstRPRI == None)
	{
		//This should never happen
		Warn("InstRPRI not found for " $ instigatedBy.GetHumanReadableName() $ " (" $ instigatedBy $ ")");
		
		if(default.bDamageLog)
			Log("=== RPGRules.NetDamage END ===");
		
		return Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	}
	
	if(Monster(injured) == None && TurretController(InjuredController) == None && InjuredRPRI == None)
	{
		//This should never happen
		Warn("InjuredRPRI not found for " $ injured.GetHumanReadableName() $ " (" $ injured $ ")");
		
		if(default.bDamageLog)
			Log("=== RPGRules.NetDamage END ===");
		
		return Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	}

	//headshot bonus EXP
	if(
		InstRPRI != None &&
		(DamageType == class'DamTypeSniperHeadShot' || DamageType == class'DamTypeClassicHeadshot') &&
		!InstigatorController.SameTeamAs(InjuredController))
	{
		if(default.bDamageLog)
			Log("DEBUG: HEADSHOT!!");
		
		InstRPRI.AwardExperience(class'RPGGameStats'.default.EXP_HeadShot);
	}
	
	if(default.bDamageLog)
		Log("DEBUG: Processing damage...");

	if(InstRPRI != None)
		Damage += int(float(Damage) * float(InstRPRI.Attack) * 0.005);
	
	if(default.bDamageLog)
		Log("DEBUG: After instigator's damage bonus: Damage = " $ Damage);
		
	if(InjuredRPRI != None)
		Damage -= int(float(Damage) * float(InjuredRPRI.Defense) * 0.005);
		
	if(default.bDamageLog)
		Log("DEBUG: After injured's damage reduction: Damage = " $ Damage);

	if(Damage < 1 && !bZeroDamage)
		Damage = 1;
		
	//if this is weapon damage done by an RPGWeapon, let it modify the damage
	if(ClassIsChildOf(DamageType, class'WeaponDamageType'))
	{
		RW = RPGWeapon(class'Util'.static.TraceBackWeapon(InstigatedBy, class<WeaponDamageType>(DamageType)));
		if(RW != None)
		{
			RW.RPGAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);

			if(default.bDamageLog)
				Log("DEBUG: After instigator's WEAPON " $ RW.ItemName $ " RPGAdjustTargetDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);
		}
	}
	bZeroDamage = bZeroDamage || Damage == 0;

	//Instigator active artifacts, active damage scaling -pd
	for(Inv = instigatedBy.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		A = RPGArtifact(Inv);
		
		if(A != None && A.bActive)
		{
			A.AdjustTargetDamage(Damage, Injured, HitLocation, Momentum, DamageType);
		
			if(default.bDamageLog)
				Log("DEBUG: After instigator's active ARTIFACT " $ A.ItemName $ " AdjustTargetDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);
		}
	}
	bZeroDamage = bZeroDamage || Damage == 0;
	
	//Instigator's vehicle magic -pd
	VM = class'VehicleMagic'.static.FindFor(instigatedBy);
	if(VM != None)
	{
		VM.AdjustTargetDamage(Damage, Injured, HitLocation, Momentum, DamageType);

		if(default.bDamageLog)
			Log("DEBUG: After instigator's active VEHICLE MAGIC " $ VM.MagicName $ " AdjustTargetDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);
	}
	bZeroDamage = bZeroDamage || Damage == 0;

	//Instigator abilities
	if(InstRPRI != None)
	{
		for(x = 0; x < InstRPRI.Abilities.length; x++)
		{
			if(InstRPRI.Abilities[x].bAllowed)
				InstRPRI.Abilities[x].HandleDamage(Damage, injured, instigatedBy, Momentum, DamageType, true);
		
			if(default.bDamageLog)
				Log("DEBUG: After instigator's ABILITY " $ InstRPRI.Abilities[x].default.AbilityName $ " HandleDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);
		}
	}
	bZeroDamage = bZeroDamage || Damage == 0;

	//Injured weapon magic
	if(RPGWeapon(injured.Weapon) != None)
	{
		RPGWeapon(injured.Weapon).RPGAdjustPlayerDamage(Damage, OriginalDamage, instigatedBy, HitLocation, Momentum, DamageType);
		
		if(default.bDamageLog)
			Log("DEBUG: After injured's WEAPON " $ RPGWeapon(injured.Weapon).ItemName $ " RPGAdjustPlayerDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);
	}
	bZeroDamage = bZeroDamage || Damage == 0;

	//Injured active artifacts, passive damage scaling -pd
	for(Inv = Injured.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		A = RPGArtifact(Inv);
		
		if(A != None && A.bActive)
		{
			A.AdjustPlayerDamage(Damage, instigatedBy, HitLocation, Momentum, DamageType);
			
			if(default.bDamageLog)
				Log("DEBUG: After injured's active ARTIFACT " $ A.ItemName $ " AdjustPlayerDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);
		}
	}
	bZeroDamage = bZeroDamage || Damage == 0;
	
	//Injured vehicle magic -pd
	VM = class'VehicleMagic'.static.FindForAnyPassenger(Injured);
	if(VM != None)
	{
		VM.AdjustPlayerDamage(Damage, instigatedBy, HitLocation, Momentum, DamageType);
	
		if(default.bDamageLog)
			Log("DEBUG: After injured's active VEHICLE MAGIC " $ VM.MagicName $ " AdjustPlayerDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);	
	}
	bZeroDamage = bZeroDamage || Damage == 0;
	
	//Injured abilities
	if(InjuredRPRI != None)
	{
		for(x = 0; x < InjuredRPRI.Abilities.length; x++)
		{
			if(InjuredRPRI.Abilities[x].bAllowed)
				InjuredRPRI.Abilities[x].HandleDamage(Damage, injured, instigatedBy, Momentum, DamageType, false);
		
			if(default.bDamageLog)
				Log("DEBUG: After injured's ABILITY " $ InjuredRPRI.Abilities[x].default.AbilityName $ " HandleDamage: Damage = " $ Damage $ ", Momentum = " $ Momentum);	
		}
	}
	bZeroDamage = bZeroDamage || Damage == 0;
	
	if(default.bDamageLog)
		Log("=== RPGRules.NetDamage END ===");

	//EXP for damage
	if(bZeroDamage || Damage < 0)
	{
		Damage = 0;
		return 0;
	}
	else
	{
		//retrieve actual damage
		Damage = Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
		
		//xp for damage
		if(InstRPRI != None)
		{
			AwardEXPForDamage(InstigatorController, InstRPRI, injured, Damage);
		}
		else if(InstigatorController.IsA('FriendlyMonsterController'))
		{
			InstRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(FriendlyMonsterController(InstigatorController).Master);
			if(InstRPRI != None)
				AwardEXPForDamage(InstigatorController, InstRPRI, injured, Damage);
		}

		return Damage;
	}
}

function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
	local RPGPlayerReplicationInfo RPRI;
	local int x;

	//increase value of ammo pickups based on Max Ammo stat
	if(Other.Controller != None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Other.Controller);
		if (RPRI != None)
		{
			if (Ammo(item) != None)
				Ammo(item).AmmoAmount = int(Ammo(item).default.AmmoAmount * (1.0 + float(RPRI.AmmoMax) / 100.f));

			for (x = 0; x < RPRI.Abilities.length; x++)
			{
				if(RPRI.Abilities[x].bAllowed)
				{
					if(RPRI.Abilities[x].OverridePickupQuery(Other, item, bAllowPickup))
						return true;
				}
			}
		}
	}

	return Super.OverridePickupQuery(Other, item, bAllowPickup);
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local Inventory Inv;
	local Weapon W;
	local RPGWeapon RW;
	local bool bAlreadyPrevented;
	local int x;
	local Controller KilledController;
	local Pawn KilledVehicleDriver;
	local RPGPlayerReplicationInfo KillerRPRI, KilledRPRI;
	local AbilityVehicleEject EjectorSeat;
	local ArtifactDoubleModifier DoubleMod;
	
	if(bGameEnded)
		return Super.PreventDeath(Killed, Killer, damageType, HitLocation);
	
	//FIXME hotfix, must find a better solution
	DoubleMod = ArtifactDoubleModifier(Killed.FindInventoryType(class'ArtifactDoubleModifier'));
	if(DoubleMod != None && DoubleMod.bActive)
		DoubleMod.GotoState('');
	
	if((PlayerController(Killer) != None || Bot(Killer) != None) && damageType != None && Killer != Killed.Controller)
	{
		if(damageType == class'DamTypeTeleFrag' || damageType == class'DamTypeTeleFragged')
		{
			if(PlayerController(Killer) != None)
			{
				PlayerController(Killer).PlayAnnouncement(EagleEyeAnnouncement, 1, true);
				PlayerController(Killer).ReceiveLocalizedMessage(class'EagleEyeMessage');
			}
			if(PlayerController(Killed.Controller) != None)
			{
				PlayerController(Killed.Controller).PlayAnnouncement(DisgraceAnnouncement, 1, true);
				PlayerController(Killed.Controller).ReceiveLocalizedMessage(class'DisgraceMessage');
			}
		}
	}

	bAlreadyPrevented = Super.PreventDeath(Killed, Killer, damageType, HitLocation);

	if (Killed.Controller != None)
		KilledController = Killed.Controller;
	else if (Killed.DrivenVehicle != None && Killed.DrivenVehicle.Controller != None)
		KilledController = Killed.DrivenVehicle.Controller;

	if (KilledController != None)
		KilledRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(KilledController);

	if(Vehicle(Killed) != None)
		KilledVehicleDriver = Vehicle(Killed).Driver;

	if (KilledRPRI != None)
	{
		if(Killed.SelectedItem != None)
			KilledRPRI.LastSelectedPowerupType = Killed.SelectedItem.class;
		else
			KilledRPRI.LastSelectedPowerupType = None;
		
		//detect whether this player switched teams
		if(Level.Game.bTeamGame && KilledRPRI.PRI.Team.TeamIndex != KilledRPRI.Team)
		{
			KilledRPRI.bTeamChanged = true; //allow RPRI to react on spawn
			
			if(KilledVehicleDriver != None)
				Inv = KilledVehicleDriver.Inventory;
			else
				Inv = Killed.Inventory;
			
			while(Inv != None)
			{
				W = Weapon(Inv);
				if(W != None && class'AbilityDenial'.static.CanSaveWeapon(W))
				{
					RW = RPGWeapon(W);
					if(RW != None)
						KilledRPRI.QueueWeapon(RW.ModifiedWeapon.class, RW.class, RW.Modifier);
					else
						KilledRPRI.QueueWeapon(W.class, None, 0);
				}

				Inv = Inv.Inventory;
			}
			
			return false; //cannot save from a team switch
		}
		else
		{
			//FIXME Pawn should probably still call PreventDeath() in cases like this, but it might be wiser to ignore the value
			if (!KilledController.bPendingDelete && (KilledController.PlayerReplicationInfo == None || !KilledController.PlayerReplicationInfo.bOnlySpectator))
			{
				for(x = 0; x < KilledRPRI.Abilities.length; x++)
				{
					if(KilledRPRI.Abilities[x].bAllowed)
					{
						if(KilledRPRI.Abilities[x].PreventDeath(Killed, Killer, damageType, HitLocation, bAlreadyPrevented))
							bAlreadyPrevented = true;
					}
				}
			}
		}
	}

	if(bAlreadyPrevented)
	{
		return true;
	}
	else //yes, ELSE. because vehicle ejection doesn't actually save the victim (the vehicle)
	{
		if(
			Killer != None &&
			Killer != KilledController &&
			KilledVehicleDriver != None)
		{
			KilledRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(KilledController);
			if (KilledRPRI == None)
			{
				Log("KilledRPRI not found for " $ Killed.GetHumanReadableName(), 'TitanRPG');
				return true;
			}
			
			EjectorSeat = AbilityVehicleEject(KilledRPRI.GetOwnedAbility(class'AbilityVehicleEject'));
			if(EjectorSeat != None && EjectorSeat.HasJustEjected())
			{
				//get data
				KillerRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Killer);
				if (KillerRPRI == None)
				{
					Log("KillerRPRI not found for " $ Killer.GetHumanReadableName(), 'TitanRPG');
					return true;
				}

				ShareExperience(KillerRPRI,
					GetKillEXP(KillerRPRI, KilledRPRI, class'RPGGameStats'.default.EXP_DestroyVehicle));

				KillerRPRI.PRI.Score += 1.f; //add a game point
				
				//reset killing spree for ejected player
				if(KilledVehicleDriver.GetSpree() > 4)
				{
					Killer.AwardAdrenaline(DeathMatch(Level.Game).ADR_MajorKill);
					ShareExperience(KillerRPRI, class'RPGGameStats'.default.EXP_EndSpree);
					DeathMatch(Level.Game).EndSpree(Killer, KilledController);
				}
				
				if(KilledVehicleDriver.IsA('UnrealPawn'))
					UnrealPawn(KilledVehicleDriver).spree = 0;
			}
		}
	}
	
	if((damageType.default.bCausedByWorld || damageType == class'DamTypeTeleFrag') && Killed.Health > 0)
	{
		//if this damagetype is an instant kill that bypasses Pawn.TakeDamage() and calls Pawn.Died() directly
		//then we need to award EXP by damage for the rest of the monster's health
		AwardEXPForDamage(Killer, class'RPGPlayerReplicationInfo'.static.GetFor(Killer), Killed, Killed.Health);
	}

	//Yet Another Invasion Hack - Invasion doesn't call ScoreKill() on the GameRules if a monster kills something
	//This one's so bad I swear I'm fixing it for a patch
	if(int(Level.EngineVersion) < 3190 && Level.Game.IsA('Invasion') && KilledController != None && MonsterController(Killer) != None)
	{
		if (KilledController.PlayerReplicationInfo != None)
			KilledController.PlayerReplicationInfo.bOutOfLives = true;

		ScoreKill(Killer, KilledController);
	}
	
	//unless another GameRules decides to prevent death, this is certain death
	if(KillerRPRI == None)
		KillerRPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Killer);
	
	if(KillerRPRI != None)
	{
		KillerRPRI.AboutToKill = Killed.Controller;
		KillerRPRI.KillingDamType = damageType;
		KillerRPRI.AdrenalineBeforeKill = Killer.Adrenaline;
	}

	return false;
}

function bool PreventSever(Pawn Killed, name boneName, int Damage, class<DamageType> DamageType)
{
	local RPGPlayerReplicationInfo RPRI;
	local int x;

	if (Killed.Controller != None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Killed.Controller);
		if (RPRI != None)
		{
			for (x = 0; x < RPRI.Abilities.length; x++)
			{
				if(RPRI.Abilities[x].bAllowed)
				{
					if(RPRI.Abilities[x].PreventSever(Killed, boneName, Damage, DamageType))
						return true;
				}
			}
		}
	}

	return Super.PreventSever(Killed, boneName, Damage, DamageType);
}

function Timer()
{
	local RPGPlayerReplicationInfo RPRI;
	local Controller C;

	if(Level.Game.bGameEnded)
	{
		//Grant exp for win
		if(class'RPGGameStats'.default.EXP_Win > 0)
		{
			if(TeamInfo(Level.Game.GameReplicationInfo.Winner) != None)
			{
				for (C = Level.ControllerList; C != None; C = C.NextController)
				{
					if (C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.Team == Level.Game.GameReplicationInfo.Winner)
					{
						RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(C);
						if (RPRI != None)
							RPRI.AwardExperience(class'RPGGameStats'.default.EXP_Win);
					}
				}
			}
			else if (PlayerReplicationInfo(Level.Game.GameReplicationInfo.Winner) != None
				  && Controller(PlayerReplicationInfo(Level.Game.GameReplicationInfo.Winner).Owner) != None )
			{
				RPRI = class'RPGPlayerReplicationInfo'.static.GetForPRI(PlayerReplicationInfo(Level.Game.GameReplicationInfo.Winner));
				if (RPRI != None)
					RPRI.AwardExperience(class'RPGGameStats'.default.EXP_Win);
			}
		}
		
		RPGMut.EndGame();
		SetTimer(0, false);
	}
}

function bool HandleRestartGame()
{
	return Super.HandleRestartGame();
}

defaultproperties
{
	DisgraceAnnouncement=Sound'<? echo($packageName); ?>.TranslocSounds.Disgrace'
	EagleEyeAnnouncement=Sound'<? echo($packageName); ?>.TranslocSounds.EagleEye'
	DirectDamageTypes(0)=class'DamTypeEmo'
	DirectDamageTypes(1)=class'DamTypePoison'
	DirectDamageTypes(2)=class'DamTypeRetaliation'
	DirectDamageTypes(3)=class'DamTypeFatality'
	NoUDamageTypes(0)=class'DamTypeRetaliation'
	bDamageLog=False
}
