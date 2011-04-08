/*
	UT2004 has a pretty detailed event tracking system - which is not used but for master server stats tracking.
	
	This is gonna change.
	RPGGameStats can react on "ScoreEvent" and "TeamScoreEvent" calls and grant experience as a conclusion.
	This should replace UT2004RPG's system of hacks and cheats.
	
	The Mutator spawns these game stats, which automatically hooks itself into the GameInfo.
	All calls are passed to the real GameStats if it existed.
	
	~pd
*/

class RPGGameStats extends GameStats
	config(TitanRPG);

//Experience for ScoreEvents
var config float 
	EXP_Frag, EXP_SelfFrag, EXP_HealPowernode, EXP_ConstructPowernode, EXP_DestroyPowernode, EXP_DestroyPowercore, EXP_DestroyConstructingPowernode,
	EXP_ReturnFriendlyFlag, EXP_ReturnEnemyFlag, EXP_FlagDenial, EXP_FlagCapFirstTouch, EXP_FlagCapAssist, EXP_FlagCapFinal, EXP_ObjectiveScore, EXP_ObjectiveCompleted, EXP_CriticalFrag,
	EXP_TeamProtectFrag, EXP_TeamFrag, EXP_BallThrownFinal, EXP_BallCapFinal, EXP_BallScoreAssist, EXP_DOMScore;

//Experience for SpecialEvents
var config float EXP_TypeKill, EXP_FirstBlood, EXP_TranslocateGib;
var config float EXP_KillingSpree[6];
var config float EXP_MultiKill[7];
var config float EXP_Resurrection; //resurrection using the Necromancy combo

//Handled externally
var config float EXP_HeadShot, EXP_EndSpree, EXP_DamagePowercore, EXP_Win, EXP_TurretKill;
var config float EXP_VehicleRepair; //EXP for repairing 1 "HP"
var config float EXP_Assist;
var config float EXP_Healing; //default damage multiplier for healing teammates (LM will scale this)
var config float EXP_TeamBooster; //EXP per second per healed player

//Ratios
var config float EXP_DestroyVehicle; //you get the XP of a normal kill multiplied by this value
var config float EXP_FriendlyMonsterKill; //you get the XP of a normal kill multiplied by this value

//Not yet featured
var config float EXP_HeadHunter, EXP_ComboWhore, EXP_FlakMonkey, EXP_RoadRampage, EXP_Hatrick;

//To avoid any issues, any call to our GameStats is passed to the actual game's GameStats
var GameStats ActualGameStats;

//Necromancy check queue
var config array<string> ResurrectionCombos;

struct NecroCheckStruct
{
	var RPGPlayerReplicationInfo RPRI;
	var int OldComboCount;
	
	var int WaitTicks;
};
var array<NecroCheckStruct> NecroCheck;

//Data to allow custom weapon stat entries for "F3" (such as Lightning Rod, Ultima etc)
struct CustomWeaponStatStruct
{
	var class<DamageType> DamageType; //if a kill is done with this damage type...
	var class<Weapon> WeaponClass; //...a kill with this weapon will be tracked
};
var config array<CustomWeaponStatStruct> CustomWeaponStats;

var bool bHooked;

event Destroyed()
{
	Super.Destroyed();
	
	if(ActualGameStats != None)
		ActualGameStats.Destroy();
	
	ActualGameStats = None;
}

event Tick(float dt)
{
	local int i;

	//Hook
	if(!bHooked)
	{
		ActualGameStats = Level.Game.GameStats;
		Level.Game.bEnableStatLogging = True;
		Level.Game.GameStats = Self;
		
		Log("Hooked RPGGameStats, ActualGameStats =" @ ActualGameStats, 'TitanRPG');
		
		bHooked = true;
	}
	
	i = 0;
	while(i < NecroCheck.Length)
	{
		if(--NecroCheck[i].WaitTicks == 0)
		{
			//if the necro combo failed, Combos[4] was set back to its old amount
			if(TeamPlayerReplicationInfo(NecroCheck[i].RPRI.PRI).Combos[4] > NecroCheck[i].OldComboCount)
				NecroCheck[i].RPRI.AwardExperience(EXP_Resurrection);
			
			NecroCheck.Remove(i, 1);
		}
		else
		{
			i++;
		}
	}
}

function Init()
{
	if(ActualGameStats != None && ActualGameStats.TempLog == None)
		ActualGameStats.Init();
}

function Shutdown()
{
	if(ActualGameStats != None)
		ActualGameStats.Shutdown();
}

function Logf(string LogString)
{
	if(ActualGameStats != None)
		ActualGameStats.Logf(LogString);
}

function NewGame()
{
	if(ActualGameStats != None)
		ActualGameStats.NewGame();
}

function ServerInfo()
{
	if(ActualGameStats != None)
		ActualGameStats.ServerInfo();
}

function StartGame()
{
	if(ActualGameStats != None)
		ActualGameStats.StartGame();
}

function EndGame(string Reason)
{
	if(ActualGameStats != None)
		ActualGameStats.EndGame(Reason);
}

function ConnectEvent(PlayerReplicationInfo Who)
{
	if(ActualGameStats != None)
		ActualGameStats.ConnectEvent(Who);
}

function DisconnectEvent(PlayerReplicationInfo Who)
{
	if(ActualGameStats != None)
		ActualGameStats.DisconnectEvent(Who);
}

function ScoreEvent(PlayerReplicationInfo Who, float Points, string Desc)
{
	/*
		Known values for ScoreEvent Desc:
		---------------------------------
		"frag"
		"self_frag"
		"heal_powernode"
		"red_powernode_constructed" - they mean power nodes, which technically are ONSPowerCore subclasses
		"blue_powernode_constructed"
		"red_powernode_destroyed"
		"blue_powernode_destroyed"
		"red_constructing_powernode_destroyed"
		"blue_constructing_powernode_destroyed"
		"red_powercore_destroyed"
		"blue_powercore_destroyed"
		"flag_ret_friendly"
		"flag_ret_enemy"
		"flag_denial"
		"flag_cap_1st_touch"
		"flag_cap_assist"
		"flag_cap_final"
		"ObjectiveScore"
		"Objective_Completed"
		"critical_frag"
		"team_protect_frag"
		"team_frag"
		"ball_thrown_final"
		"ball_cap_final"
		"ball_score_assist"
		"dom_score"
	*/
	local RPGPlayerReplicationInfo RPRI;
	local float x;
	local int i;
	local ONSPowerCore PowerCore;
	local bool bShareExperience;

	if(ActualGameStats != None)
		ActualGameStats.ScoreEvent(Who, Points, Desc);

	x = 0;
	if(Desc == "frag")
	{
		//Handled by RPGRules
		return;
		
		/*
		x = EXP_Frag;
		bShareExperience = true;
		*/
	}
	else if(Desc == "self_frag")
	{
		x = EXP_SelfFrag;
	}
	else if(Desc == "heal_powernode")
	{
		x = EXP_HealPowernode;
		bShareExperience = true;
	}
	else if(Desc == "red_powernode_constructed" || Desc == "blue_powernode_constructed")
	{
		x = EXP_ConstructPowernode;
	}
	else if(Desc == "red_powernode_destroyed" || Desc == "blue_powernode_destroyed")
	{
		x = EXP_DestroyPowernode;
	}
	else if(Desc == "red_powercore_destroyed" || Desc == "blue_powercore_destroyed")
	{
		x = EXP_DestroyPowercore;
		
		//Grant EXP to Scorers
		foreach AllActors(class'ONSPowerCore', PowerCore)
		{
			if(PowerCore.bFinalCore)
			{
				for(i = 0; i < PowerCore.Scorers.Length; i++)
				{
					RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(PowerCore.Scorers[i].C);
					if(RPRI != None)
						RPRI.AwardExperience(EXP_DamagePowercore * 100.f * PowerCore.Scorers[i].Pct);
				}
			}
		}
	}
	else if(Desc == "red_constructing_powernode_destroyed" || Desc == "blue_constructing_powernode_destroyed")
	{
		x = EXP_DestroyConstructingPowernode;
	}
	else if(Desc == "flag_ret_friendly")
	{
		x = EXP_ReturnFriendlyFlag;
	}
	else if(Desc == "flag_ret_enemy")
	{
		x = EXP_ReturnEnemyFlag;
	}
	else if(Desc == "flag_denial")
	{
		x = EXP_FlagDenial;
	}
	else if(Desc == "flag_cap_1st_touch")
	{
		x = EXP_FlagCapFirstTouch;
	}
	else if(Desc == "flag_cap_assist")
	{
		x = EXP_FlagCapAssist;
	}
	else if(Desc == "flag_cap_final")
	{
		x = EXP_FlagCapFinal;
	}
	else if(Desc == "ObjectiveScore")
	{
		x = EXP_ObjectiveScore;
		bShareExperience = true;
	}
	else if(Desc == "Objective_Completed")
	{
		x = EXP_ObjectiveCompleted * Points;
	}
	else if(Desc == "critical_frag")
	{
		x = EXP_CriticalFrag;
		bShareExperience = true;
	}
	else if(Desc == "team_protect_frag")
	{
		x = EXP_TeamProtectFrag;
		bShareExperience = true;
	}
	else if(Desc == "team_frag")
	{
		x = EXP_TeamFrag;
		bShareExperience = true;
	}
	else if(Desc == "ball_thrown_final")
	{
		x = EXP_BallThrownFinal;
	}
	else if(Desc == "ball_cap_final")
	{
		x = EXP_BallCapFinal;
	}
	else if(Desc == "ball_score_assist")
	{
		x = EXP_BallScoreAssist;
	}
	else if(Desc == "dom_score")
	{
		x = EXP_DOMScore;
	}
	else
	{
		Log("Unknown score event: " $ Desc, 'TitanRPG');
	}
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetForPRI(Who);
	if(x != 0 && RPRI != None)
	{
		if(bShareExperience)
			class'RPGRules'.static.ShareExperience(RPRI, x);
		else
			RPRI.AwardExperience(x);
	}
}


function TeamScoreEvent(int Team, float Points, string Desc)
{
	/*
		Known values for TeamScoreEvent Desc:
		-------------------------------------
		"enemy_core_destroyed"
		"tdm_frag"
		"flag_cap"
		"game_objective_score"
		"team_frag"
		"tdm_frag"
		"pair_of_round_winner"
		"ball_tossed"
		"ball_carried"
		"dom_teamscore"
	*/
	if(ActualGameStats != None)
		ActualGameStats.TeamScoreEvent(Team, Points, Desc);
}

static function RegisterWeaponKill(PlayerReplicationInfo Killer, PlayerReplicationInfo Victim, class<Weapon> WeaponClass)
{
	local int i;
	local bool bFound;
	local TeamPlayerReplicationInfo TPRI;
	local TeamPlayerReplicationInfo.WeaponStats NewWeaponStats;
	
	if(WeaponClass == None)
		return;

	//kill for the killer
	TPRI = TeamPlayerReplicationInfo(Killer);
	if(TPRI != None)
	{
		bFound = false;
		for (i = 0; i < TPRI.WeaponStatsArray.Length; i++ )
		{
			if(TPRI.WeaponStatsArray[i].WeaponClass == WeaponClass)
			{
				TPRI.WeaponStatsArray[i].Kills++;
				bFound = true;
				break;
			}
		}

		if(!bFound)
		{
			NewWeaponStats.WeaponClass = WeaponClass;
			NewWeaponStats.Kills = 1;
			NewWeaponStats.Deaths = 0;
			NewWeaponStats.DeathsHolding = 0;
			TPRI.WeaponStatsArray[TPRI.WeaponStatsArray.Length] = NewWeaponStats;
		}
	}
	
	//death for the victim
	TPRI = TeamPlayerReplicationInfo(Victim);
	if(TPRI != None)
	{
		bFound = false;
		for (i = 0; i < TPRI.WeaponStatsArray.Length; i++ )
		{
			if(TPRI.WeaponStatsArray[i].WeaponClass == WeaponClass)
			{
				TPRI.WeaponStatsArray[i].Deaths++;
				bFound = true;
				break;
			}
		}

		if(!bFound)
		{
			NewWeaponStats.WeaponClass = WeaponClass;
			NewWeaponStats.Kills = 0;
			NewWeaponStats.Deaths = 1;
			NewWeaponStats.DeathsHolding = 0;
			TPRI.WeaponStatsArray[TPRI.WeaponStatsArray.Length] = NewWeaponStats;
		}
	}
}

function KillEvent(string Killtype, PlayerReplicationInfo Killer, PlayerReplicationInfo Victim, class<DamageType> Damage)
{
	/*
		Known values for KillEvent Killtype:
		-------------------------------------
		"K" - Kill
		"TK" - Teamkill
	*/
	local int i;
	local class<Weapon> WeaponClass;
	
	if(ActualGameStats != None)
		ActualGameStats.KillEvent(Killtype, Killer, Victim, Damage);
	
	//add a custom kill to the WeaponStats - thanks to BattleMode's RPG for this method!
	//Retrieve custom weapon class
	WeaponClass = None;
	for(i = 0; i < CustomWeaponStats.Length; i++)
	{
		if(CustomWeaponStats[i].DamageType == Damage)
		{
			WeaponClass = CustomWeaponStats[i].WeaponClass;
			break;
		}
	}
	
	if(WeaponClass != None)
		RegisterWeaponKill(Killer, Victim, WeaponClass);
}

static function bool IsResurrectionCombo(string ComboName)
{
	local int i;
	
	for(i = 0; i < default.ResurrectionCombos.Length; i++)
	{
		if(InStr(ComboName, default.ResurrectionCombos[i]) >= 0)
			return true;
	}
	
	return false;
}

function SpecialEvent(PlayerReplicationInfo Who, string Desc)
{
	/*
		Known values for SpecialEvent Desc:
		-------------------------------------
		"type_kill"
		"first_blood"
		"spree_X" - X is the 1-based level of the spree (1 = Killing Spree, 2 = Rampage etc.)
		"multikill_X" - X is the (0- or 1-based ??) level of the multi kill (0 = Double Kill, 1 = Multi Kill etc.)
		"translocate_gib"
	*/
	local RPGPlayerReplicationInfo RPRI;
	local NecroCheckStruct N;
	local float x, i;
	
	if(ActualGameStats != None)
		ActualGameStats.SpecialEvent(Who, Desc);
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetForPRI(Who);
	if(RPRI == None)
		return;
		
	if(Desc == "type_kill")
	{
		x = EXP_TypeKill;
	}
	else if(Desc == "first_blood")
	{
		x = EXP_FirstBlood;
	}
	else if(Left(Desc, 6) == "spree_")
	{
		i = Min(5, int(Mid(Desc, 6)));
		x = EXP_KillingSpree[i];
	}
	else if(Left(Desc, 10) == "multikill_")
	{
		i = Min(6, int(Mid(Desc, 10)));
		x = EXP_MultiKill[i];
	}
	else if(Desc == "translocate_gib")
	{
		x = EXP_TranslocateGib;
	}
	else if(IsResurrectionCombo(Desc))
	{
		N.RPRI = RPRI;
		N.OldComboCount = TeamPlayerReplicationInfo(RPRI.PRI).Combos[4];
		N.WaitTicks = 3; //wait a few ticks, because the necro combo isn't done before the next
		NecroCheck[NecroCheck.Length] = N;
	}
	else
	{
		//Log("Unhandled special event for" @ Who.PlayerName $ ":" @ Desc);
	}
	
	if(x != 0)
		RPRI.AwardExperience(x);
}

function GameEvent(string GEvent, string Desc, PlayerReplicationInfo Who)
{
	/*
		Known values for GameEvent GEvent:
		-------------------------------------
		"flag_returned_timeout"
		"flag_dropped"
		"flag_taken"
		"flag_pickup"
		"flag_returned"
		"flag_captured"
		"NameChange"
		"TeamChange"
		"EndRound_Trophy"
		"AS_attackers_win"
		"AS_defenders_win"
		"AS_BeginRound"
		"ObjectedCompleted_Trophy"
		"VehicleDestroyed_Trophy"
		"bomb_dropped"
		"bomb_taken"
		"bomb_pickup"
		"bomb_returned_timeout"
	*/
	if(ActualGameStats != None)
		ActualGameStats.GameEvent(GEvent, Desc, Who);
}

function string GetLogFilename()
{
	if(ActualGameStats != None)
		return ActualGameStats.GetLogFilename();
	else
		return "";
}

defaultproperties
{
	CustomWeaponStats(0)=(DamageType=Class'DamTypeTitanUltima',WeaponClass=Class'DummyWeaponUltima')
	CustomWeaponStats(1)=(DamageType=Class'DamTypeUltima',WeaponClass=Class'DummyWeaponUltima')
	CustomWeaponStats(2)=(DamageType=Class'DamTypeLightningRod',WeaponClass=Class'DummyWeaponLightningRod')
	CustomWeaponStats(3)=(DamageType=Class'DamTypeCounterShove',WeaponClass=Class'DummyWeaponCounterShove')
	CustomWeaponStats(4)=(DamageType=Class'DamTypePoison',WeaponClass=Class'DummyWeaponPoison')
	CustomWeaponStats(5)=(DamageType=Class'DamTypeRetaliation',WeaponClass=Class'DummyWeaponRetaliation')
	CustomWeaponStats(6)=(DamageType=Class'DamTypeSelfDestruct',WeaponClass=Class'DummyWeaponSelfDestruct')
	CustomWeaponStats(7)=(DamageType=Class'DamTypeEmo',WeaponClass=Class'DummyWeaponEmo')
	CustomWeaponStats(8)=(DamageType=Class'DamTypeMegaExplosion',WeaponClass=Class'DummyWeaponMegaBlast')
	CustomWeaponStats(9)=(DamageType=Class'DamTypeRepulsion',WeaponClass=Class'DummyWeaponRepulsion')
	CustomWeaponStats(10)=(DamageType=Class'DamTypeVorpal',WeaponClass=Class'DummyWeaponVorpal')

	//Original game values
	EXP_Frag=1.00
	EXP_SelfFrag=0.00 //-1.00 really, but we don't want to lose exp here
	EXP_HealPowernode=1.00
	EXP_ConstructPowernode=2.50
	EXP_DestroyPowernode=5.00
	EXP_DestroyConstructingPowernode=0.16
	EXP_DestroyPowercore=0.00 //not necessarily much of an accomplishment, pct of damage done should be the measure
	EXP_ReturnFriendlyFlag=3.00
	EXP_ReturnEnemyFlag=5.00
	EXP_FlagDenial=7.00
	EXP_FlagCapFirstTouch=5.00
	EXP_FlagCapAssist=5.00
	EXP_FlagCapFinal=5.00
	EXP_ObjectiveScore=0.00
	EXP_ObjectiveCompleted=1.00
	EXP_CriticalFrag=1.00
	EXP_TeamProtectFrag=0.00
	EXP_TeamFrag=0.00
	EXP_BallThrownFinal=5.00
	EXP_BallCapFinal=8.00 //5.00 really, but assist is 5.00 too for this... compensated
	EXP_BallScoreAssist=2.00
	EXP_DOMScore=5.00
	
	//Custom values
	EXP_TypeKill=0.00
	EXP_FirstBlood=5.00
	EXP_TranslocateGib=0.00
	EXP_KillingSpree(0)=5.00
	EXP_KillingSpree(1)=5.00
	EXP_KillingSpree(2)=5.00
	EXP_KillingSpree(3)=5.00
	EXP_KillingSpree(4)=5.00
	EXP_KillingSpree(5)=5.00
	EXP_MultiKill(0)=5.00
	EXP_MultiKill(1)=5.00
	EXP_MultiKill(2)=5.00
	EXP_MultiKill(3)=5.00
	EXP_MultiKill(4)=5.00
	EXP_MultiKill(5)=5.00
	EXP_MultiKill(6)=5.00
	
	//Handled externally
	EXP_HeadShot=1.00
	EXP_EndSpree=5.00
	EXP_DamagePowercore=0.50 //experience for 1% damage
	EXP_Win=30
	EXP_TurretKill=1.00 //kill by a constructed turret
	
	EXP_VehicleRepair=0.005 //experience for repairing one "health point"
	
	EXP_Assist=15.00 //Score Assist

	EXP_Healing=0.01
	EXP_TeamBooster=0.10 //per second per healed player (excluding yourself)
	
	EXP_Resurrection=50.00 //experience for resurrecting another player using the Necromancy combo
	
	//Ratios
	EXP_DestroyVehicle=0.67
	EXP_FriendlyMonsterKill=0.50
	
	//Not yet featured
	EXP_HeadHunter=10.00;
	EXP_ComboWhore=10.00;
	EXP_FlakMonkey=10.00;
	EXP_RoadRampage=10.00;
	EXP_Hatrick=10.00;
	
	//Resurrection
	ResurrectionCombos(0)="ComboNecro"
	ResurrectionCombos(1)="ComboRevival"
}
