class AbilityAdrenalineSurge extends RPGAbility;

function ScoreKill(Controller Killer, Controller Killed, bool bOwnedByKiller)
{
	if(!bOwnedByKiller)
		return;

	if (Killed.Level.Game.IsA('Invasion') && Killed.Pawn != None && Killed.Pawn.IsA('Monster'))
	{
		Killer.AwardAdrenaline(float(Killed.Pawn.GetPropertyText("ScoringValue")) * default.BonusPerLevel * AbilityLevel);
		return;
	}

	if ( !(!Killed.Level.Game.bTeamGame || ((Killer != None) && (Killer != Killed) && (Killed != None)
		&& (Killer.PlayerReplicationInfo != None) && (Killed.PlayerReplicationInfo != None)
		&& (Killer.PlayerReplicationInfo.Team != Killed.PlayerReplicationInfo.Team))) )
		return;	//no bonus for team kills or suicides

	if (UnrealPlayer(Killer) != None && UnrealPlayer(Killer).MultiKillLevel > 0)
		Killer.AwardAdrenaline(Deathmatch(Killer.Level.Game).ADR_MajorKill * default.BonusPerLevel * AbilityLevel);

	if (UnrealPawn(Killed.Pawn) != None && UnrealPawn(Killed.Pawn).spree > 4)
		Killer.AwardAdrenaline(Deathmatch(Killer.Level.Game).ADR_MajorKill * default.BonusPerLevel * AbilityLevel);

	if ( Killer.PlayerReplicationInfo.Kills == 1 && TeamPlayerReplicationInfo(Killer.PlayerReplicationInfo) != None
	     && TeamPlayerReplicationInfo(Killer.PlayerReplicationInfo).bFirstBlood )
		Killer.AwardAdrenaline(Deathmatch(Killer.Level.Game).ADR_MajorKill * default.BonusPerLevel * AbilityLevel);

	if (Killer.bIsPlayer && Killed.bIsPlayer)
		Killer.AwardAdrenaline(Deathmatch(Killer.Level.Game).ADR_Kill * default.BonusPerLevel * AbilityLevel);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Adrenal Surge"
	Description="For each level of this ability, you gain $1 more adrenaline from all kill related adrenaline bonuses."
	StartingCost=10
	CostAddPerLevel=0
	MaxLevel=2
	BonusPerLevel=0.500000
	RequiredAbilities(0)=(AbilityClass=Class'AbilityAdrenalineMax',Level=10)
	RequiredAbilities(1)=(AbilityClass=Class'AbilityDamageBonus',Level=6)
	ForbiddenAbilities(0)=(AbilityClass=Class'AbilityLoadedWeapons',Level=1)
}
