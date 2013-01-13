class Ability_AdrenalineSurge extends RPGAbility;

function ScoreKill(Controller Killed, class<DamageType> DamageType)
{
	if(Level.Game.IsA('Invasion') && Monster(Killed.Pawn) != None)
	{
		Instigator.Controller.AwardAdrenaline(Monster(Killed.Pawn).ScoringValue * BonusPerLevel * AbilityLevel);
	}
	else
	{
		if(Killed != Instigator.Controller && !Killed.SameTeamAs(Instigator.Controller))
		{
			if(UnrealPlayer(Instigator.Controller) != None && UnrealPlayer(Instigator.Controller).MultiKillLevel > 0)
				Instigator.Controller.AwardAdrenaline(Deathmatch(Level.Game).ADR_MajorKill * BonusPerLevel * AbilityLevel);
			
			if(UnrealPawn(Killed.Pawn) != None && UnrealPawn(Killed.Pawn).spree > 4)
				Instigator.Controller.AwardAdrenaline(Deathmatch(Level.Game).ADR_MajorKill * BonusPerLevel * AbilityLevel);

			if(
				Instigator.Controller.PlayerReplicationInfo.Kills == 1 &&
				TeamPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo) != None &&
				TeamPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo).bFirstBlood
			)
			{
				Instigator.Controller.AwardAdrenaline(Deathmatch(Level.Game).ADR_MajorKill * BonusPerLevel * AbilityLevel);
			}
		
			if(Killed.bIsPlayer)
				Instigator.Controller.AwardAdrenaline(Deathmatch(Level.Game).ADR_Kill * BonusPerLevel * AbilityLevel);
		}
	}
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
	Category=class'AbilityCategory_Adrenaline'
}
